// utils/src/salary_ledger.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/salary_ledger_model.dart';
import 'package:leadcapture/utils/src/extensions.dart';
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

      // Filter by month
      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }

      // Filter by user
      if (userId?.isNotEmpty == true) {
        query = query.where('userId', isEqualTo: userId!.encrypt);
      }

      final snapshot = await query.get(
        const GetOptions(source: Source.serverAndCache),
      );

      List<SalaryModel> result = [];

      for (final doc in snapshot.docs) {
        // ✅ data is guaranteed non-null with Query<Map<String, dynamic>>
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

  static Future<SalarySummary> getMonthlySummary(int month) async {
    final ledger = await getSalaryLedger(month: month);

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

  /// ✅ Create salary deduction (from permission)
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
      final perHourSalary = monthlySalary / (workingDays * 8);
      final perMinuteSalary = perHourSalary / 60;

      final present = int.parse(attendance.present);
      final absent = int.parse(attendance.absent);

      final earnedSalary = present * perDaySalary;

      final absentDeduction = absent * perDaySalary;

      double permissionDeduction = 0;

      for (final permission in attendance.permissions) {
        switch (permission) {
          case PermissionType.leaveFullDay:
            permissionDeduction += perDaySalary;
            break;

          case PermissionType.leaveHalfDay:
            permissionDeduction += perDaySalary * 0.5;
            break;

          case PermissionType.lateEntry:
            permissionDeduction += perDaySalary * 0.1;
            break;

          case PermissionType.earlyExit:
            permissionDeduction += perDaySalary * 0.1;
            break;

          case PermissionType.permission:
            permissionDeduction += perDaySalary * 0.25;
            break;

          case PermissionType.workFromHome:
            break;
        }
      }

      final lessMinutes = double.tryParse(attendance.lessHourMinutes) ?? 0.0;

      final lessHourDeduction = lessMinutes * perMinuteSalary;

      final otMinutes = double.tryParse(attendance.otHourMinutes) ?? 0.0;

      final otHours = otMinutes / 60;

      final otAmount = otHours * perHourSalary * 1.5;

      const incentiveAmount = 0.0;

      final grossPay = earnedSalary + otAmount + incentiveAmount;

      final pfAmount = grossPay * 0.12;
      final esiAmount = grossPay * 0.0075;
      const advanceDeduction = 0.0;

      final totalDeduction =
          absentDeduction +
          permissionDeduction +
          lessHourDeduction +
          pfAmount +
          esiAmount +
          advanceDeduction;

      final netPay = grossPay - totalDeduction;

      final salary = SalaryModel(
        salaryNumber: monthCode.toString(),
        employeeId: attendance.employeeId,
        permissionId: attendance.permissions.map((e) => e.name).join(','),
        workingDays: present.toString(),
        leaveDays: absent.toString(),
        otHours: otHours.toStringAsFixed(2),
        earnAmount: earnedSalary.toStringAsFixed(2),
        otAmount: otAmount.toStringAsFixed(2),
        incentive: "0",
        grossPay: grossPay.toStringAsFixed(2),
        otherDeduction: permissionDeduction.toStringAsFixed(2),
        pfAmount: "0",
        esiAmount: "0",
        advanceDeduction: "0",
        totalDeduction: totalDeduction.toStringAsFixed(2),
        netPay: netPay.toStringAsFixed(2),
        salaryFromDate: DateTime(year, month, 1).toIso8601String(),
        salaryToDate: DateTime(year, month + 1, 0).toIso8601String(),
      );

      /// SAVE ONE DOCUMENT PER MONTH
      await firebase.users
          .doc(cid)
          .collection(Collections.salaryLedger.name)
          .doc("${attendance.employeeId}_$monthCode")
          .set(salary.toMap());
    } catch (e) {
      print("Salary processing error: $e");
    }
  }

  // Get working days in month (Sat/Sun excluded)
  static int _getWorkingDays(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    int workingDays = 0;

    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      final day = firstDay.add(Duration(days: i));
      if (day.weekday < 6) workingDays++; // Mon-Fri only
    }
    return workingDays.clamp(20, 26);
  }

  static Future<AttendanceModel> getAttendanceSummary(int monthCode) async {
    try {
      final salaries = await getSalaryLedger(month: monthCode);

      // if (salaries.isEmpty) {
      //   return AttendanceModel.empty();
      // }

      int presentDays = 0;
      int holidayCount = 0;
      int absentCount = 0;
      int permissionCount = 0;

      for (final salary in salaries) {
        presentDays += int.tryParse(salary.workingDays) ?? 0;
      }

      final year = (monthCode / 100).floor();
      final month = (monthCode % 100);
      final workingDays = _getWorkingDays(year, month);

      absentCount = (workingDays - presentDays).clamp(0, workingDays);

      return AttendanceModel(
        employeeId: salaries.isNotEmpty ? salaries.first.employeeId : '',
        punchList: [],
        present: presentDays.toString(),
        holiday: holidayCount.toString(),
        absent: absentCount.toString(),
        workingHourMinutes: '0',
        lessHourMinutes: '0',
        otHourMinutes: '0',
        permissions: List.generate(
          permissionCount,
          (_) => PermissionType.permission,
        ),
      );
    } catch (e) {
      print("Attendance summary error: $e");

      return AttendanceModel(
        punchList: [],
        present: '0',
        holiday: '0',
        absent: '0',
        workingHourMinutes: '0',
        lessHourMinutes: '0',
        otHourMinutes: '0',
        permissions: [],
        employeeId: '',
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
