// utils/src/salary_ledger.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/salary_ledger_model.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';
import '/constants/constants.dart';
import '/services/services.dart';

class SalaryLedgerService {
  static FirebaseConfig firebase = FirebaseConfig();

  static Future<List<SalaryModel>> getSalaryLedger({
    int? month,
    String? userId,
  }) async {
    try {
      final cid = await Spdb.getCid();
      if (cid == null) return [];

      Query<Map<String, dynamic>> query = firebase.users
          .doc(cid)
          .collection(Collections.salaryLedger.name)
          .orderBy('createdAt', descending: true);
      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }
      if (userId?.isNotEmpty == true) {
        query = query.where('employeeId', isEqualTo: userId);
      }
      final snapshot = await query.get(
        const GetOptions(source: Source.serverAndCache),
      );
      List<SalaryModel> result = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final typedData = <String, dynamic>{...data, 'id': doc.id};
        result.add(SalaryModel.fromMap(typedData));
      }
      return result;
    } catch (e) {
      print("Salary ledger fetch error: $e");
      return [];
    }
  }

  static Future<SalarySummary> getMonthlySummary(
    int month, {
    String? userId,
  }) async {
    final ledger = await getSalaryLedger(month: month, userId: userId);
    final totalNetPay = ledger.fold<double>(
      0,
      (sum, item) => sum + double.parse(item.netPay),
    );
    final totalGrossPay = ledger.fold<double>(
      0,
      (sum, item) => sum + double.parse(item.grossPay),
    );
    final totalDeductions = ledger.fold<double>(
      0,
      (sum, item) => sum + double.parse(item.totalDeduction),
    );
    final totalOtHours = ledger.fold<double>(
      0,
      (sum, item) => sum + double.parse(item.otHours),
    );
    return SalarySummary(
      month: month,
      totalAmount: totalNetPay,
      totalDeductions: totalDeductions,
      totalHours: totalOtHours,
      totalGrossPay: totalGrossPay,
      items: ledger,
    );
  }

  static Future<void> createDeduction(SalaryModel model) async {
    try {
      final cid = await Spdb.getCid();
      await firebase.users
          .doc(cid!)
          .collection(Collections.salaryLedger.name)
          .add(model.toMap());
    } catch (e) {
      throw "Failed to create salary deduction: $e";
    }
  }

  static Future<void> processMonthlySalary({
    required int monthCode,
    required AttendanceModel attendance,
  }) async {
    try {
      final cid = await Spdb.getCid();
      if (cid == null) return;

      final year = (monthCode / 100).floor();
      final month = (monthCode % 100);
      final workingDays = _getWorkingDays(year, month);
      const monthlySalary = 30000.0;
      final perDaySalary = monthlySalary / workingDays;
      final perHourSalary = perDaySalary / 8;
      final perMinuteSalary = perHourSalary / 60;
      final present = int.tryParse(attendance.present) ?? 0;
      final leaveDays = (workingDays - present).clamp(0, workingDays);
      final earnedSalary = present * perDaySalary;
      final permissionCounts = <PermissionType, int>{};

      double permissionDeduction = 0;

      permissionDeduction +=
          (permissionCounts[PermissionType.leaveHalfDay] ?? 0) *
          (perDaySalary * 0.5);

      permissionDeduction +=
          (permissionCounts[PermissionType.lateEntry] ?? 0) *
          (perDaySalary * 0.1);

      permissionDeduction +=
          (permissionCounts[PermissionType.earlyExit] ?? 0) *
          (perDaySalary * 0.1);

      permissionDeduction +=
          (permissionCounts[PermissionType.permission] ?? 0) *
          (perHourSalary * 2);

      final lessHourDeduction = attendance.lessHourMinutes * perMinuteSalary;
      final otHours = attendance.otHourMinutes / 60;
      const otMultiplier = 1.5;
      final otAmount = otHours * perHourSalary * otMultiplier;
      double incentive = 0;
      if (present == workingDays) {
        incentive = 2000; // you can change this rule
      }
      final grossPay = earnedSalary + otAmount + incentive;
      final pfAmount = earnedSalary * 0.12;
      final esiAmount = earnedSalary * 0.0075;
      const advanceDeduction = 0.0;
      final totalDeduction =
          permissionDeduction +
          lessHourDeduction +
          pfAmount +
          esiAmount +
          advanceDeduction;
      final netPay = (grossPay - totalDeduction).clamp(0, double.infinity);

      final salary = SalaryModel(
        salaryNumber: monthCode.toString(),
        employeeId: attendance.employeeId,
        workingDays: present.toString(),
        leaveDays: leaveDays.toString(),
        otHours: otHours.toStringAsFixed(2),
        earnAmount: earnedSalary.toStringAsFixed(2),
        otAmount: otAmount.toStringAsFixed(2),
        incentive: incentive.toStringAsFixed(2),
        grossPay: grossPay.toStringAsFixed(2),
        otherDeduction: permissionDeduction.toStringAsFixed(2),
        pfAmount: pfAmount.toStringAsFixed(2),
        esiAmount: esiAmount.toStringAsFixed(2),
        advanceDeduction: advanceDeduction.toStringAsFixed(2),
        totalDeduction: totalDeduction.toStringAsFixed(2),
        netPay: netPay.toStringAsFixed(2),
        salaryFromDate: DateTime(year, month, 1).toIso8601String(),
        salaryToDate: DateTime(year, month + 1, 0).toIso8601String(),
      );

      await firebase.users
          .doc(cid)
          .collection(Collections.salaryLedger.name)
          .doc("${attendance.employeeId}_$monthCode")
          .set({
            ...salary.toMap(),
            "month": monthCode,
            "createdAt": DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      print("Salary processing error: $e");
    }
  }

  static int _getWorkingDays(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    int workingDays = 0;

    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      final day = firstDay.add(Duration(days: i));
      if (day.weekday < 6) workingDays++; // Mon-Fri only
    }
    return workingDays;
  }

  static Future<AttendanceModel> getAttendanceSummary(int monthCode) async {
    try {
      final uid = await Spdb.getUid();
      if (uid == null) throw "User not found";
      final year = (monthCode / 100).floor();
      final month = (monthCode % 100);
      final fromDate = DateTime(year, month, 1);
      final toDate = DateTime(year, month + 1, 0);
      final attendanceList =
          await AttendanceService.getMonthlyAttendanceSummary(
            userUid: uid,
            fromDate: fromDate,
            toDate: toDate,
          );

      int presentDays = 0;
      int totalLessMinutes = 0;
      int totalOtMinutes = 0;

      for (final a in attendanceList) {
        presentDays += int.tryParse(a.present) ?? 0;
        totalLessMinutes += a.lessHourMinutes;
        totalOtMinutes += a.otHourMinutes;
      }

      final workingDays = _getWorkingDays(year, month);
      final absentDays = (workingDays - presentDays).clamp(0, workingDays);
      List<PermissionType> permissions = [];

      for (final a in attendanceList) {
        if (a.punchList.isNotEmpty) {
          final punch = a.punchList.first;

          if (punch.permissionType != null &&
              punch.permissionStatus == PermissionsStatus.approved) {
            permissions.add(punch.permissionType!);
          }
        }
      }

      return AttendanceModel(
        employeeId: uid,
        punchList: [],
        breakMinutes: 0,
        present: presentDays.toString(),
        holiday: "0",
        absent: absentDays.toString(),
        workingHourMinutes: 0,
        lessHourMinutes: totalLessMinutes,
        otHourMinutes: totalOtMinutes,
      );
    } catch (e) {
      print("Attendance summary error: $e");

      return AttendanceModel(
        employeeId: '',
        punchList: [],
        breakMinutes: 0,
        present: '0',
        holiday: '0',
        absent: '0',
        workingHourMinutes: 0,
        lessHourMinutes: 0,
        otHourMinutes: 0,
        permissions: [],
      );
    }
  }

  static Future<SalaryModel> getSalarySummary({
    required String userUid,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      var cid = await Spdb.getCid();

      if (cid == null) {
        throw "CollectionId cannot be null";
      }

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.salaryLedger.name)
          .where("employeeId", isEqualTo: userUid)
          .where(
            "salaryFromDate",
            isGreaterThanOrEqualTo: fromDate.toIso8601String(),
          )
          .where("salaryToDate", isLessThanOrEqualTo: toDate.toIso8601String())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return SalaryModel(
          salaryNumber: "",
          employeeId: userUid,
          permissionId: "",
          workingDays: "0",
          leaveDays: "0",
          otHours: "0",
          earnAmount: "0",
          otAmount: "0",
          incentive: "0",
          grossPay: "0",
          otherDeduction: "0",
          pfAmount: "0",
          esiAmount: "0",
          advanceDeduction: "0",
          totalDeduction: "0",
          netPay: "0",
          salaryFromDate: fromDate.toIso8601String(),
          salaryToDate: toDate.toIso8601String(),
        );
      }

      var doc = snapshot.docs.first;

      return SalaryModel.fromMap({...doc.data(), "uid": doc.id});
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<AttendanceModel> getAttendanceSummaryForUser(
    String userId,
    int monthCode,
  ) async {
    final year = (monthCode / 100).floor();
    final month = (monthCode % 100);

    final fromDate = DateTime(year, month, 1);
    final toDate = DateTime(year, month + 1, 0);

    final attendanceList = await AttendanceService.getMonthlyAttendanceSummary(
      userUid: userId,
      fromDate: fromDate,
      toDate: toDate,
    );

    int presentDays = 0;
    int totalLessMinutes = 0;
    int totalOtMinutes = 0;

    for (final a in attendanceList) {
      presentDays += int.tryParse(a.present) ?? 0;
      totalLessMinutes += a.lessHourMinutes;
      totalOtMinutes += a.otHourMinutes;
    }

    return AttendanceModel(
      employeeId: userId,
      punchList: [],
      breakMinutes: 0,
      present: presentDays.toString(),
      holiday: "0",
      absent: "0",
      workingHourMinutes: 0,
      lessHourMinutes: totalLessMinutes,
      otHourMinutes: totalOtMinutes,
      permissions: [],
    );
  }

  static Future<void> processSalaryForAllEmployees(int monthCode) async {
  try {
    final cid = await Spdb.getCid();
    if (cid == null) return;

    final employeesSnapshot =
        await firebase.users.doc(cid).collection(Collections.users.name).get();

    for (final doc in employeesSnapshot.docs) {
      final userId = doc.id;
      final attendance = await getAttendanceSummaryForUser(userId, monthCode);
      await processMonthlySalary(monthCode: monthCode, attendance: attendance);
    }
  } catch (e) {
    print("Error processing salary for all employees: $e");
  }
}
}

class SalarySummary {
  final int month;
  final double totalAmount;
  final double totalDeductions;
  final double totalHours;
  final double totalGrossPay;
  final List<SalaryModel> items;

  SalarySummary({
    required this.month,
    required this.totalAmount,
    required this.totalDeductions,
    required this.totalHours,
    required this.totalGrossPay,
    required this.items,
  });
}
