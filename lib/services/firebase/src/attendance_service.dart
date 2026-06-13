import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/filter_model.dart';
import 'package:leadcapture/models/src/holiday_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/firebase_config.dart';
import 'package:leadcapture/views/screens/attendance/attendance_helper.dart';

class AttendanceService {
  static FirebaseConfig firebase = FirebaseConfig();

  static Future<String> createPunch({
    required String userUid,
    required int workingMinutes,
    required int otMinutes,
    required int lessMinutes,
    String status = "present",
  }) async {
    try {
      var cid = await Spdb.getCid();
      var user = await Spdb.getUser();
      var uid = await Spdb.getUid();
      String result = "";

      if (cid != null) {
        var now = DateTime.now().millisecondsSinceEpoch;

        var punchData = {
          'punchDate': DateTime.now().toIso8601String(),
          'punchTime': [DateTime.now().toIso8601String()],
          'userUid': uid,
          'userName': user.name,
          'workingMinutes': workingMinutes,
          'otMinutes': otMinutes,
          'lessMinutes': lessMinutes,
          'status': status,
          'created': DateTime.now().millisecondsSinceEpoch,
          'clockIn': now,
          'clockOut': null,
          'permissionType': null,
          'permissionStatus': null,
        };

        var docRef = await firebase.users
            .doc(cid)
            .collection(Collections.attendance.name)
            .add(punchData);

        result = docRef.id;
      }

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> clockOut(String punchId) async {
    try {
      var cid = await Spdb.getCid();
      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.attendance.name)
            .doc(punchId)
            .update({
              "clockOut": DateTime.now().millisecondsSinceEpoch,
              "modified": DateTime.now().millisecondsSinceEpoch,
            });
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<AttendanceModel> getAttendance({
    required FilterModel filter,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var query = firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where(
            'created',
            isGreaterThanOrEqualTo: filter.fromDate.millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: filter.toDate.millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true)
          .limit(filter.pageLimit);

      var snapshot = await query.get();
      List<PunchModel> punchList = [];

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          punchList.add(PunchModel.fromMap({...doc.data(), 'uid': doc.id}));
        }
      }

      return AttendanceModel(
        employeeId: uid ?? '',
        punchList: punchList,
        breakMinutes: 0,
        present: punchList.length.toString(),
        holiday: '0',
        absent: '0',
        workingHourMinutes: 0,
        lessHourMinutes: 0,
        otHourMinutes: 0,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<bool> checkTodayPunch() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        0,
        0,
        0,
      ).millisecondsSinceEpoch;

      var todayEnd = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where('created', isGreaterThanOrEqualTo: todayStart)
          .where('created', isLessThanOrEqualTo: todayEnd)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<int> getTodayPunchCount() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        0,
        0,
        0,
      ).millisecondsSinceEpoch;

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where('created', isGreaterThanOrEqualTo: todayStart)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> addPermissionToPunch({
    required String punchId,
    required PermissionType permissionType,
  }) async {
    try {
      var cid = await Spdb.getCid();

      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.attendance.name)
            .doc(punchId)
            .update({
              'permissionType': permissionType.toString().split('.').last,
              'permissionStatus': PermissionsStatus.pending.name,
              'modified': DateTime.now().millisecondsSinceEpoch,
            });
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<AttendanceModel>> attendanceListing({
    required FilterModel filter,
  }) async {
    try {
      List<AttendanceModel> data = [];
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      int skipCount = (filter.pageNumber - 1) * filter.pageLimit;

      var query = firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where(
            'created',
            isGreaterThanOrEqualTo: filter.fromDate.millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: filter.toDate.millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true)
          .limit(filter.pageLimit);

      if (skipCount > 0) {
        var previousSnapshot = await query.get();
        if (previousSnapshot.docs.length >= skipCount) {
          var lastVisible = previousSnapshot.docs[skipCount - 1];
          query = query.startAfterDocument(lastVisible);
        }
      }

      var snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          data.add(AttendanceModel.fromMap({...doc.data(), 'uid': doc.id}));
        }
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<AttendanceModel> getDashboardAttendance({
    required DateTime date,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var dayStart = DateTime(
        date.year,
        date.month,
        date.day,
        0,
        0,
        0,
      ).millisecondsSinceEpoch;
      var dayEnd = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where('created', isGreaterThanOrEqualTo: dayStart)
          .where('created', isLessThanOrEqualTo: dayEnd)
          .get();

      List<PunchModel> punchList = snapshot.docs.map((doc) {
        return PunchModel.fromMap({...doc.data(), 'uid': doc.id});
      }).toList();

      return AttendanceModel(
        employeeId: uid ?? '',
        punchList: punchList,
        breakMinutes: 0,
        present: punchList.length.toString(),
        holiday: '0',
        absent: '0',
        workingHourMinutes: 0,
        lessHourMinutes: 0,
        otHourMinutes: 0,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> updateAttendance({
    required String id,
    required AttendanceModel model,
  }) async {
    try {
      var cid = await Spdb.getCid();

      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.attendance.name)
            .doc(id)
            .update(model.toMap());
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<int> attendanceCount() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var count = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .count()
          .get();

      return count.count ?? 0;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<AttendanceModel>> getMonthlyAttendanceSummary({
    required String userUid,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var workSnap = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: userUid)
          .where(
            'clockIn',
            isGreaterThanOrEqualTo: fromDate.millisecondsSinceEpoch,
          )
          .where('clockIn', isLessThanOrEqualTo: toDate.millisecondsSinceEpoch)
          .get();

      var permissionSnap = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where('userId', isEqualTo: userUid)
          .where('from', isLessThanOrEqualTo: toDate.millisecondsSinceEpoch)
          .where('to', isGreaterThanOrEqualTo: fromDate.millisecondsSinceEpoch)
          .get();

      Map<String, WorktimeModel> workMap = {
        for (var doc in workSnap.docs)
          DateTime.fromMillisecondsSinceEpoch(
            doc['clockIn'],
          ).toIso8601String().split('T').first: WorktimeModel.fromMap(
            doc.id,
            doc.data(),
          ),
      };

      Map<String, Map<String, dynamic>> permissionMap = {};

      for (var doc in permissionSnap.docs) {
        final data = doc.data();

        DateTime from = DateTime.fromMillisecondsSinceEpoch(data['from']);
        DateTime to = DateTime.fromMillisecondsSinceEpoch(data['to']);

        for (
          DateTime d = from;
          !d.isAfter(to);
          d = d.add(const Duration(days: 1))
        ) {
          final key = d.toIso8601String().split('T').first;
          permissionMap[key] = data;
        }
      }

      List<AttendanceModel> result = [];
      final today = DateTime.now();

      for (
        DateTime d = fromDate;
        d.isBefore(today.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        if (d.isAfter(today)) break;

        final key = d.toIso8601String().split('T').first;
        WorktimeModel? work = workMap[key];

        if (d.weekday == DateTime.sunday) {
          result.add(
            AttendanceModel(
              employeeId: userUid,
              worktime: work,
              punchList: [
                PunchModel(
                  punchDate: key,
                  punchTime: [],
                  totalHours: "00:00",
                  lessHours: "00:00",
                  otHours: "00:00",
                  status: AttendanceStatus.absent.name,
                  day: d.weekday.toString(),
                  otApproval: "0",
                ),
              ],
              breakMinutes: 0,
              present: "0",
              absent: "0",
              holiday: "1",
              workingHourMinutes: 0,
              lessHourMinutes: 0,
              otHourMinutes: 0,
            ),
          );
          continue;
        }

        final permission = permissionMap[key];

        int workingMinutes = 0;
        int otMinutes = 0;
        int lessMinutes = 0;

        String status = AttendanceStatus.absent.name;

        if (work != null) {
          final tempModel = attendanceWorktime(work);
          workingMinutes = tempModel.workingHourMinutes;
          lessMinutes = tempModel.lessHourMinutes;
          otMinutes = tempModel.otHourMinutes;
          status = tempModel.punchList.first.status;
        }

        if (permission != null) {
          final type = permission['type'];
          final pStatus = permission['status'];

          if (pStatus == PermissionsStatus.approved.name) {
            switch (type) {
              case "leaveFullDay":
                status = AttendanceStatus.leave.name;
                workingMinutes = 0;
                break;

              case "leaveHalfDay":
                status = AttendanceStatus.halfDay.name;
                break;

              case "workFromHome":
                status = AttendanceStatus.present.name;
                break;

              case "lateEntry":
                status = AttendanceStatus.late.name;
                break;

              case "earlyExit":
                status = AttendanceStatus.earlyExit.name;
                break;

              case "permission":
                status = AttendanceStatus.present.name;
                break;
            }
          } else if (pStatus == PermissionsStatus.pending.name) {
            status = "Pending";
          } else if (pStatus == PermissionsStatus.rejected.name) {
            status = "Rejected";
          }
        }

        result.add(
          AttendanceModel(
            employeeId: userUid,
            worktime: work,
            punchList: [
              PunchModel(
                punchDate: key,
                punchTime: [],
                totalHours: _minutesToHHmm(workingMinutes),
                lessHours: _minutesToHHmm(lessMinutes),
                otHours: _minutesToHHmm(otMinutes),
                status: status,
                day: d.weekday.toString(),
                otApproval: "0",
              ),
            ],
            breakMinutes: 0,
            present:
                (status == AttendanceStatus.present.name ||
                    status == AttendanceStatus.late.name ||
                    status == AttendanceStatus.earlyExit.name ||
                    status == AttendanceStatus.wfh.name)
                ? "1"
                : "0",
            absent: status == AttendanceStatus.absent.name ? "1" : "0",
            holiday: "0",
            workingHourMinutes: workingMinutes,
            lessHourMinutes: lessMinutes,
            otHourMinutes: otMinutes,
          ),
        );
      }

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static String _minutesToHHmm(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = mins.toString().padLeft(2, '0');

    return "$hStr:$mStr";
  }

  static Future<AttendanceStats> getAttendanceStats({
    required String userUid,
    required DateTime fromDate,
    required DateTime toDate,
    required List<HolidayModel> holidays,
  }) async {
    var monthlyAttendance = await getMonthlyAttendanceSummary(
      userUid: userUid,
      fromDate: fromDate,
      toDate: toDate,
    );

    int presentDays = 0;
    int absentDays = 0;
    int leaveDays = 0;
    int holidayDays = 0;
    int wfhDays = 0;
    int halfDayDays = 0;
    int lateDays = 0;
    int earlyExitDays = 0;

    int pendingDays = 0;
    int rejectedDays = 0;
    int permissionDays = 0;

    double totalWorkingHours = 0;
    double totalLessHours = 0;
    double totalOTHours = 0;

    bool isHoliday(DateTime date) {
      return holidays.any(
        (h) =>
            h.date.year == date.year &&
            h.date.month == date.month &&
            h.date.day == date.day,
      );
    }

    for (var a in monthlyAttendance) {
      final punch = a.punchList.isNotEmpty ? a.punchList.first : null;

      DateTime? date = punch != null ? parseDateTime(punch.punchDate) : null;

      // 🚨 1. HOLIDAY CHECK FIRST (NO PUNCH REQUIRED)
      if (date != null && isHoliday(date)) {
        holidayDays++;
        continue;
      }

      // 🚨 2. NO PUNCH → ABSENT
      if (punch == null) {
        absentDays++;
        continue;
      }

      // 🚨 3. WORK HOURS (ONLY VALID DAYS)
      totalWorkingHours += a.workingHourMinutes;
      totalLessHours += a.lessHourMinutes;
      totalOTHours += a.otHourMinutes;

      // 🚨 4. PENDING / REJECTED FIRST
      if (punch.permissionStatus == PermissionsStatus.pending) {
        pendingDays++;
        continue;
      }

      if (punch.permissionStatus == PermissionsStatus.rejected) {
        rejectedDays++;
        continue;
      }

      // 🚨 5. APPROVED PERMISSIONS
      if (punch.permissionStatus == PermissionsStatus.approved &&
          punch.permissionType != null) {
        switch (punch.permissionType!) {
          case PermissionType.leaveFullDay:
            leaveDays++;
            continue;

          case PermissionType.leaveHalfDay:
            halfDayDays++;
            presentDays++;
            continue;

          case PermissionType.workFromHome:
            wfhDays++;
            presentDays++;
            continue;

          case PermissionType.lateEntry:
            lateDays++;
            presentDays++;
            continue;

          case PermissionType.earlyExit:
            earlyExitDays++;
            presentDays++;
            continue;

          case PermissionType.permission:
            permissionDays++;
            presentDays++;
            continue;
        }
      }

      // 🚨 6. NORMAL ATTENDANCE
      switch (punch.status.toLowerCase()) {
        case "present":
          presentDays++;
          break;

        case "late":
          lateDays++;
          presentDays++;
          break;

        case "earlyexit":
          earlyExitDays++;
          presentDays++;
          break;

        case "halfday":
          halfDayDays++;
          presentDays++;
          break;

        case "absent":
          absentDays++;
          break;
      }
    }

    return AttendanceStats(
      presentDays: presentDays,
      absentDays: absentDays,
      leaveDays: leaveDays,
      holidayDays: holidayDays,
      wfhDays: wfhDays,
      halfDayDays: halfDayDays,
      lateDays: lateDays,
      earlyExitDays: earlyExitDays,

      pendingDays: pendingDays,
      rejectedDays: rejectedDays,
      permissionDays: permissionDays,

      totalWorkingHours: totalWorkingHours.toStringAsFixed(1),
      totalLessHours: totalLessHours.toStringAsFixed(1),
      totalOTHours: totalOTHours.toStringAsFixed(1),

      attendanceData: monthlyAttendance,
    );
  }

  static Future generateTodayAttendance() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      if (cid == null || uid == null) return;
      DateTime now = DateTime.now();
      int start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      int end = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      var existing = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where('created', isGreaterThanOrEqualTo: start)
          .where('created', isLessThanOrEqualTo: end)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return;

      var worktime = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .where('clockIn', isGreaterThanOrEqualTo: start)
          .where('clockIn', isLessThanOrEqualTo: end)
          .limit(1)
          .get();

      if (worktime.docs.isEmpty) return;
      var data = worktime.docs.first.data();
      DateTime clockIn = DateTime.fromMillisecondsSinceEpoch(data['clockIn']);
      DateTime clockOut = data['clockOut'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['clockOut'])
          : now;
      int totalMinutes = clockOut.difference(clockIn).inMinutes;
      int breakMinutes = 0;
      if (data['breaks'] != null) {
        Map breaks = data['breaks'];
        for (var b in breaks.values) {
          if (b['start'] != null && b['end'] != null) {
            DateTime startBreak = DateTime.parse(b['start']);
            DateTime endBreak = DateTime.parse(b['end']);
            breakMinutes += endBreak.difference(startBreak).inMinutes;
          }
        }
      }

      int workingMinutes = totalMinutes - breakMinutes;
      String status;
      if (workingMinutes >= 480) {
        status = AttendanceStatus.present.name;
      } else if (workingMinutes >= 240) {
        status = AttendanceStatus.halfDay.name;
      } else {
        status = AttendanceStatus.absent.name;
      }
      String? permissionType;
      var permission = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where("userId", isEqualTo: uid)
          .where("status", isEqualTo: "approved")
          .where("from", isLessThanOrEqualTo: end)
          .where("to", isGreaterThanOrEqualTo: start)
          .get();

      if (permission.docs.isNotEmpty) {
        permissionType = permission.docs.first.data()["type"];

        switch (permissionType) {
          case "leaveFullDay":
            status = AttendanceStatus.leave.name;
            break;

          case "leaveHalfDay":
            status = AttendanceStatus.halfDay.name;
            break;

          case "workFromHome":
            status = AttendanceStatus.present.name;
            break;
        }
      }

      await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .add({
            "userUid": uid,
            "workingMinutes": workingMinutes,
            "breakMinutes": breakMinutes,
            "status": status,
            "permissionType": permissionType,
            "permissionStatus": "approved",
            "created": DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> updatePermissionStatus({
    required String punchId,
    required PermissionsStatus status,
  }) async {
    try {
      var cid = await Spdb.getCid();

      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.attendance.name)
            .doc(punchId)
            .update({
              "permissionStatus": status.name,
              "modified": DateTime.now().millisecondsSinceEpoch,
            });

        if (status == PermissionsStatus.approved) {
          await applyPermissionToAttendance(punchId: punchId);
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> applyPermissionToAttendance({
    required String punchId,
  }) async {
    try {
      var cid = await Spdb.getCid();
      if (cid == null) return;
      var punchDoc = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .doc(punchId)
          .get();

      if (!punchDoc.exists) return;

      var punchData = punchDoc.data()!;
      String? permissionType = punchData['permissionType'];
      String? permissionStatus = punchData['permissionStatus'];

      if (permissionStatus == PermissionsStatus.approved.name &&
          permissionType != null) {
        String status = punchData['status'] ?? AttendanceStatus.present;

        switch (permissionType) {
          case "leaveFullDay":
            status = AttendanceStatus.leave.name;
            break;

          case "leaveHalfDay":
            status = AttendanceStatus.halfDay.name;
            break;

          case "workFromHome":
            status = AttendanceStatus.present.name;
            break;

          case "lateEntry":
          case "earlyExit":
          case "permission":
            status = AttendanceStatus.present.name;
            break;
        }

        await firebase.users
            .doc(cid)
            .collection(Collections.attendance.name)
            .doc(punchId)
            .update({
              "status": status,
              "modified": DateTime.now().millisecondsSinceEpoch,
            });
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<AttendanceModel>> getAllAttendance({
    required FilterModel filter,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var query = firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where(
            'created',
            isGreaterThanOrEqualTo: filter.fromDate.millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: filter.toDate.millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true)
          .limit(filter.pageLimit);

      var snapshot = await query.get();

      List<AttendanceModel> data = [];

      for (var doc in snapshot.docs) {
        data.add(AttendanceModel.fromMap({...doc.data(), 'uid': doc.id}));
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> updateAttendanceFromPermission({
    required String userId,
    required String permissionId,
    required PermissionsStatus status,
  }) async {
    try {
      var cid = await Spdb.getCid();
      if (cid == null) return;

      final permissionDoc = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc(permissionId)
          .get();

      if (!permissionDoc.exists) return;

      final permission = permissionDoc.data()!;

      DateTime from = DateTime.fromMillisecondsSinceEpoch(permission['from']);
      String type = permission['type'];

      final start = DateTime(
        from.year,
        from.month,
        from.day,
      ).millisecondsSinceEpoch;

      final end = DateTime(
        from.year,
        from.month,
        from.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      final attendanceSnap = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: userId)
          .where('created', isGreaterThanOrEqualTo: start)
          .where('created', isLessThanOrEqualTo: end)
          .limit(1)
          .get();

      if (attendanceSnap.docs.isEmpty) return;

      final doc = attendanceSnap.docs.first;
      final docRef = doc.reference;

      String newStatus = doc['status'];

      if (status == PermissionsStatus.approved) {
        switch (type) {
          case "leaveFullDay":
            newStatus = AttendanceStatus.leave.name;
            break;

          case "leaveHalfDay":
            newStatus = AttendanceStatus.halfDay.name;
            break;

          case "workFromHome":
            newStatus = AttendanceStatus.present.name;
            break;

          case "lateEntry":
          case "earlyExit":
          case "permission":
            newStatus = AttendanceStatus.present.name;
            break;
        }
      } else if (status == PermissionsStatus.rejected) {
        // revert logic if needed
        newStatus = doc['status'];
      }

      await docRef.update({
        "status": newStatus,
        "permissionType": type,
        "permissionStatus": status.name,
        "modified": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}
