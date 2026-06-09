import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/holiday_model.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';

String getEmployeeSummary(List<AttendanceModel> list) {
  int present = 0;
  int absent = 0;

  for (var a in list) {
    final status = getAttendanceStatus(a);
    if (status == "Present") present++;
    if (status == "Absent") absent++;
  }

  return "P: $present  A: $absent";
}

AttendanceModel attendanceWorktime(WorktimeModel work) {
  int totalMinutes = 0;
  int breakMinutes = 0;

  if (work.clockOut != null) {
    totalMinutes = work.clockOut!.difference(work.clockIn).inMinutes;
  } else {
    totalMinutes = DateTime.now().difference(work.clockIn).inMinutes;
  }

  work.breaks.forEach((key, value) {
    final start = parseDateTime(value['start']);
    final end = parseDateTime(value['end']);

    if (start != null && end != null) {
      breakMinutes += end.difference(start).inMinutes;
    }
  });

  final actualWork = totalMinutes - breakMinutes;
  final workMinutes = actualWork;

  final inHour = work.clockIn.hour;
  final inMin = work.clockIn.minute;
  final isLate = inHour > 9 || (inHour == 9 && inMin > 15);

  bool isEarly = false;
  if (work.clockOut != null) {
    final outHour = work.clockOut!.hour;
    final outMin = work.clockOut!.minute;
    isEarly = outHour < 17 || (outHour == 17 && outMin < 45);
  }

  AttendanceStatus status;
  if (workMinutes >= 480) {
    if (isLate) {
      status = AttendanceStatus.late;
    } else if (isEarly) {
      status = AttendanceStatus.earlyExit;
    } else {
      status = AttendanceStatus.present;
    }
  } else if (workMinutes >= 240) {
    status = AttendanceStatus.halfDay;
  } else {
    status = AttendanceStatus.absent;
  }

  String formatMinutes(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    return "${h}h ${r}m";
  }

  final punch = PunchModel(
    punchDate: work.clockIn.toIso8601String(),
    clockIn: work.clockIn.millisecondsSinceEpoch,
    clockOut: work.clockOut?.millisecondsSinceEpoch,
    punchTime: [
      work.clockIn.toIso8601String(),
      if (work.clockOut != null) work.clockOut!.toIso8601String(),
    ],
    totalHours: formatMinutes(workMinutes),
    lessHours: workMinutes < 480 ? formatMinutes(480 - workMinutes) : "0h 0m",
    status: status.name, // ✅ enum → string
    day: DateFormat('EEEE').format(work.clockIn),
    otHours: workMinutes > 480 ? formatMinutes(workMinutes - 480) : "0h 0m",
    otApproval: "Pending",
  );

  return AttendanceModel(
    employeeId: work.userUid,
    worktime: work,
    punchList: [punch],
    breakMinutes: breakMinutes,
    status: status,
    present:
        (status == AttendanceStatus.present ||
            status == AttendanceStatus.late ||
            status == AttendanceStatus.earlyExit)
        ? "1"
        : "0",
    absent: status == AttendanceStatus.absent ? "1" : "0",
    holiday: "0",

    workingHourMinutes: actualWork,
    lessHourMinutes: actualWork < 480 ? 480 - actualWork : 0,
    otHourMinutes: actualWork > 480 ? actualWork - 480 : 0,
  );
}

AttendanceStats calculateStats(
  List<AttendanceModel> list, {
  required bool isAdmin,
  required List<HolidayModel> holidays,
}) {
  int present = 0;
  int absent = 0;
  int leave = 0;
  int holidayCount = 0;
  int wfh = 0;
  int halfDay = 0;
  int late = 0;
  int earlyExit = 0;

  int pending = 0;
  int rejected = 0;
  int permission = 0;
  int inProgress = 0;
  int lessHours = 0;

  int totalWorking = 0;
  int totalLess = 0;
  int totalOT = 0;

  bool isHoliday(DateTime date) {
    return holidays.any(
      (h) =>
          h.date.year == date.year &&
          h.date.month == date.month &&
          h.date.day == date.day,
    );
  }

  if (isAdmin) {
    final empIdsPresent = <String>{};
    final empIdsAbsent = <String>{};
    final empIdsLeave = <String>{};
    final empIdsHoliday = <String>{};
    final empIdsWfh = <String>{};
    final empIdsHalfDay = <String>{};
    final empIdsLate = <String>{};
    final empIdsEarlyExit = <String>{};
    final empIdsPending = <String>{};
    final empIdsRejected = <String>{};
    final empIdsPermission = <String>{};
    final empIdsInProgress = <String>{};
    final empIdsLessHours = <String>{};

    for (var a in list) {
      final empId = a.employeeId;

      if (a.punchList.isEmpty) {
        empIdsAbsent.add(empId);
        continue;
      }

      final punchDate = parseDateTime(a.punchList.first.punchDate);
      if (punchDate == null) continue;

      final isHolidayDay = isHoliday(punchDate);

      // ✅ 1. HOLIDAY PRIORITY (HIGHEST)
      if (isHolidayDay) {
        empIdsHoliday.add(empId);
        continue; // 🚨 stop further processing
      }

      final updated = a.applyPermissions(isAdmin: isAdmin);

      // ✅ 2. PERMISSION HANDLING
      if (a.permissions != null && a.permissions!.isNotEmpty) {
        final approved = a.permissions!
            .where((p) => p.status == PermissionsStatus.approved)
            .toList();

        final pendingList = a.permissions!
            .where((p) => p.status == PermissionsStatus.pending)
            .toList();

        final rejectedList = a.permissions!
            .where((p) => p.status == PermissionsStatus.rejected)
            .toList();

        if (pendingList.isNotEmpty) empIdsPending.add(empId);
        if (rejectedList.isNotEmpty) empIdsRejected.add(empId);

        bool skipAttendance = false;

        for (var p in approved) {
          switch (p.type) {
            case PermissionType.leaveFullDay:
              empIdsLeave.add(empId);
              skipAttendance = true;
              break;

            case PermissionType.leaveHalfDay:
              empIdsHalfDay.add(empId);
              break;

            case PermissionType.workFromHome:
              empIdsWfh.add(empId);
              skipAttendance = true;
              break;

            case PermissionType.lateEntry:
              empIdsLate.add(empId);
              break;

            case PermissionType.earlyExit:
              empIdsEarlyExit.add(empId);
              break;

            case PermissionType.permission:
              empIdsPermission.add(empId);
              break;
          }
        }

        if (skipAttendance) continue;
      }

      // ✅ 3. NO PUNCH → ABSENT
      if (updated.punchList.isEmpty) {
        empIdsAbsent.add(empId);
        continue;
      }

      // ✅ 4. ATTENDANCE STATUS
      final status = getAttendanceStatus(updated);

      switch (status) {
        case "Present":
          empIdsPresent.add(empId);
          break;

        case "Late":
          empIdsLate.add(empId);
          empIdsPresent.add(empId);
          break;

        case "EarlyExit":
          empIdsEarlyExit.add(empId);
          empIdsPresent.add(empId);
          break;

        case "Absent":
          empIdsAbsent.add(empId);
          break;

        case "LessHours":
          empIdsLessHours.add(empId);
          break;

        case "InProgress":
          empIdsInProgress.add(empId);
          break;
      }

      // ✅ 5. TIME CALCULATIONS
      totalWorking += updated.workingHourMinutes;
      totalLess += updated.lessHourMinutes;
      totalOT += updated.otHourMinutes;
    }

    present = empIdsPresent.length;
    absent = empIdsAbsent.length;
    leave = empIdsLeave.length;
    holidayCount = empIdsHoliday.length;
    wfh = empIdsWfh.length;
    halfDay = empIdsHalfDay.length;
    late = empIdsLate.length;
    earlyExit = empIdsEarlyExit.length;
    pending = empIdsPending.length;
    rejected = empIdsRejected.length;
    permission = empIdsPermission.length;
    inProgress = empIdsInProgress.length;
    lessHours = empIdsLessHours.length;
  } else {
    for (var a in list) {
      if (a.punchList.isEmpty) {
        absent++;
        continue;
      }

      final punchDate = parseDateTime(a.punchList.first.punchDate);
      if (punchDate == null) continue;

      final isHolidayDay = isHoliday(punchDate);

      // ✅ 1. HOLIDAY PRIORITY (HIGHEST)
      if (isHolidayDay) {
        holidayCount++;
        continue; // 🚨 stop further processing
      }

      final updated = a.applyPermissions(isAdmin: isAdmin);

      // ✅ 2. PERMISSION HANDLING
      if (a.permissions != null && a.permissions!.isNotEmpty) {
        final approved = a.permissions!
            .where((p) => p.status == PermissionsStatus.approved)
            .toList();

        final pendingList = a.permissions!
            .where((p) => p.status == PermissionsStatus.pending)
            .toList();

        final rejectedList = a.permissions!
            .where((p) => p.status == PermissionsStatus.rejected)
            .toList();

        if (pendingList.isNotEmpty) pending++;
        if (rejectedList.isNotEmpty) rejected++;

        bool skipAttendance = false;

        for (var p in approved) {
          switch (p.type) {
            case PermissionType.leaveFullDay:
              leave++;
              skipAttendance = true;
              break;

            case PermissionType.leaveHalfDay:
              halfDay++;
              break;

            case PermissionType.workFromHome:
              wfh++;
              skipAttendance = true;
              break;

            case PermissionType.lateEntry:
              late++;
              break;

            case PermissionType.earlyExit:
              earlyExit++;
              break;

            case PermissionType.permission:
              permission++;
              break;
          }
        }

        if (skipAttendance) continue;
      }

      // ✅ 3. NO PUNCH → ABSENT
      if (updated.punchList.isEmpty) {
        absent++;
        continue;
      }

      // ✅ 4. ATTENDANCE STATUS
      final status = getAttendanceStatus(updated);

      switch (status) {
        case "Present":
          present++;
          break;

        case "Late":
          late++;
          present++;
          break;

        case "EarlyExit":
          earlyExit++;
          present++;
          break;

        case "Absent":
          absent++;
          break;

        case "LessHours":
          lessHours++;
          break;

        case "InProgress":
          inProgress++;
          break;
      }

      // ✅ 5. TIME CALCULATIONS
      totalWorking += updated.workingHourMinutes;
      totalLess += updated.lessHourMinutes;
      totalOT += updated.otHourMinutes;
    }
  }

  return AttendanceStats(
    presentDays: present,
    absentDays: absent,
    leaveDays: leave,
    holidayDays: holidayCount,
    wfhDays: wfh,
    halfDayDays: halfDay,
    lateDays: late,
    earlyExitDays: earlyExit,

    pendingDays: pending,
    rejectedDays: rejected,
    permissionDays: permission,
    inProgressDays: inProgress,
    lessHoursDays: lessHours,

    totalWorkingHours: formatMinutes(totalWorking),
    totalLessHours: formatMinutes(totalLess),
    totalOTHours: formatMinutes(totalOT),

    attendanceData: list,
  );
}

String getAttendanceStatus(AttendanceModel a) {
  if (a.punchList.isEmpty) return "Absent";
  final punch = a.punchList.first;
  if (punch.permissionStatus == PermissionsStatus.pending) {
    return "Pending";
  }
  if (punch.permissionStatus == PermissionsStatus.rejected) {
    return _calculateWorkingStatus(a);
  }
  if (punch.permissionStatus == PermissionsStatus.approved &&
      punch.permissionType != null) {
    switch (punch.permissionType!) {
      case PermissionType.leaveFullDay:
        return "Leave";
      case PermissionType.leaveHalfDay:
        return "HalfDay";
      case PermissionType.workFromHome:
        return "WFH";
      case PermissionType.lateEntry:
        return "Late";
      case PermissionType.earlyExit:
        return "EarlyExit";
      case PermissionType.permission:
        return "Permission";
    }
  }
  if (punch.clockIn != null && punch.clockOut == null) {
    return "InProgress";
  }
  return _calculateWorkingStatus(a);
}

String getPermissionStatus(WorkPermissionModel p) {
  if (p.status == PermissionsStatus.rejected) {
    return "Rejected";
  }

  if (p.status == PermissionsStatus.pending) {
    return "Pending";
  }

  switch (p.type) {
    case PermissionType.leaveFullDay:
      return "Leave";

    case PermissionType.leaveHalfDay:
      return "HalfDay";

    case PermissionType.workFromHome:
      return "WFH";

    case PermissionType.lateEntry:
      return "Late";

    case PermissionType.earlyExit:
      return "EarlyExit";

    case PermissionType.permission:
      return "Permission";
  }
}

String _calculateWorkingStatus(AttendanceModel a) {
  final workedMinutes = a.workingHourMinutes;

  if (workedMinutes == 0) return "Absent";
  if (workedMinutes >= 480) {
    final timeData = getAttendanceTime(a);
    if (timeData.checkIn != null) {
      final inHour = timeData.checkIn!.hour;
      final inMin = timeData.checkIn!.minute;
      if (inHour > 9 || (inHour == 9 && inMin > 15)) {
        return "Late";
      }
    }
    if (timeData.checkOut != null) {
      final outHour = timeData.checkOut!.hour;
      final outMin = timeData.checkOut!.minute;
      if (outHour < 17 || (outHour == 17 && outMin < 45)) {
        return "EarlyExit";
      }
    }
    return "Present";
  }
  if (workedMinutes >= 240) return "HalfDay";
  if (workedMinutes > 0 && workedMinutes < 240) return "LessHours";
  return "Absent";
}

String getStatus(AttendanceModel a) {
  final status = getAttendanceStatus(a);

  switch (status) {
    case "Present":
      return "PP";
    case "Absent":
      return "AA";
    case "HalfDay":
      return "HD";
    case "Leave":
      return "LV";
    case "WFH":
      return "WFH";
    case "Late":
      return "LT";
    case "EarlyExit":
      return "EE";
    case "Permission":
      return "PR";
    case "InProgress":
      return "IP";
    case "LessHours":
      return "LH";
    case "Pending":
      return "PD";
    default:
      return "--";
  }
}

String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
}

DateTime? parseDateTime(dynamic time) {
  if (time == null) return null;

  if (time is int) {
    return DateTime.fromMillisecondsSinceEpoch(time);
  } else if (time is String) {
    return DateTime.tryParse(time);
  } else if (time.runtimeType.toString() == 'Timestamp') {
    return time.toDate();
  }

  return null;
}

Color statusColor(String status) {
  switch (status) {
    case "Present":
      return Colors.green;

    case "Absent":
      return Colors.red;

    case "Leave":
      return Colors.orange;

    case "WFH":
      return Colors.blue;

    case "HalfDay":
      return Colors.amber;

    case "Late":
      return Colors.purple;

    case "EarlyExit":
      return Colors.deepOrange;

    case "Pending":
      return Colors.orange;

    case "Rejected":
      return Colors.redAccent;

    case "LessHours":
      return Colors.brown;

    case "InProgress":
      return Colors.blueGrey;

    default:
      return Colors.grey;
  }
}

Color getstatusColor(String status) {
  switch (status) {
    case "PP":
      return Colors.green;
    case "AA":
      return Colors.red;
    case "HD":
      return Colors.orange;
    case "HH":
      return Colors.blue;
    case "WFH":
      return Colors.purple;
    case "LT":
    case "EE":
    case "LH":
      return Colors.deepOrange;
    case "PD":
      return Colors.grey;
    default:
      return Colors.black;
  }
}

List<Session> buildSessions(List<PunchModel> punchList) {
  List<Session> sessions = [];

  for (int i = 0; i < punchList.length; i += 2) {
    final inPunch = punchList[i];
    final outPunch = (i + 1 < punchList.length) ? punchList[i + 1] : null;
    sessions.add(
      Session(inTime: inPunch.clockInDate, outTime: outPunch?.clockOutDate),
    );
  }
  return sessions;
}

List<DataCell> buildSessionCells(List<Session> sessions, DateTime? date) {
  final now = DateTime.now();

  bool isToday =
      date != null &&
      date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;

  List<DataCell> cells = [];

  for (int i = 0; i < 3; i++) {
    if (i < sessions.length) {
      final session = sessions[i];

      bool isCurrentlyWorking =
          isToday && session.inTime != null && session.outTime == null;

      cells.add(
        DataCell(
          Text(
            session.inTime != null
                ? DateFormat('HH:mm').format(session.inTime!)
                : "-",
          ),
        ),
      );

      cells.add(
        DataCell(
          Text(
            session.outTime != null
                ? DateFormat('HH:mm').format(session.outTime!)
                : isCurrentlyWorking
                ? "Working..."
                : "-",
          ),
        ),
      );
    } else {
      cells.add(const DataCell(Text("-")));
      cells.add(const DataCell(Text("-")));
    }
  }
  return cells;
}

List<Session> buildSessionsFromWorktime(WorktimeModel w) {
  List<Session> sessions = [];
  DateTime currentIn = w.clockIn;
  final sortedBreaks = (w.breaks).entries.toList()
    ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
  if (sortedBreaks.isEmpty) {
    if (w.clockOut != null) {
      sessions.add(Session(inTime: currentIn, outTime: w.clockOut));
    } else {
      sessions.add(Session(inTime: currentIn, outTime: null));
    }
    return sessions;
  }
  for (var entry in sortedBreaks) {
    final b = entry.value;

    if (b['start'] == null || b['end'] == null) continue;

    final breakStart = (b['start'] as Timestamp).toDate();
    final breakEnd = (b['end'] as Timestamp).toDate();

    sessions.add(Session(inTime: currentIn, outTime: breakStart));

    currentIn = breakEnd;
  }
  sessions.add(Session(inTime: currentIn, outTime: w.clockOut));
  return sessions;
}

int calculateBreakMinutes(Map<String, dynamic> breaks) {
  int total = 0;

  for (var b in breaks.values) {
    final start = (b['start'] as Timestamp).toDate();
    final end = (b['end'] as Timestamp).toDate();

    total += end.difference(start).inMinutes;
  }

  return total;
}

int calculateWorkMinutes(WorktimeModel w) {
  if (w.clockOut == null) return 0;

  final total = w.clockOut!.difference(w.clockIn).inMinutes;
  final breakMins = calculateBreakMinutes(w.breaks);

  return total - breakMins;
}

Map<String, List<WorktimeModel>> groupByUser(List<WorktimeModel> list) {
  Map<String, List<WorktimeModel>> map = {};

  for (var w in list) {
    map.putIfAbsent(w.userUid, () => []).add(w);
  }

  return map;
}

class AttendanceTimeData {
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  AttendanceTimeData({this.date, this.checkIn, this.checkOut});
}

AttendanceTimeData getAttendanceTime(AttendanceModel a) {
  // ✅ PRIORITY 1: Worktime
  if (a.worktime != null) {
    return AttendanceTimeData(
      date: a.worktime!.clockIn,
      checkIn: a.worktime!.clockIn,
      checkOut: a.worktime!.clockOut,
    );
  }

  // ✅ PRIORITY 2: Punch
  if (a.punchList.isNotEmpty) {
    final punch = a.punchList.first;

    DateTime? date;
    if (punch.clockInDate != null) {
      date = punch.clockInDate;
    } else if (punch.punchDate.isNotEmpty) {
      date = DateTime.tryParse(punch.punchDate);
    }

    return AttendanceTimeData(
      date: date,
      checkIn: punch.clockIn != null
          ? DateTime.fromMillisecondsSinceEpoch(punch.clockIn!)
          : null,
      checkOut: punch.clockOut != null
          ? DateTime.fromMillisecondsSinceEpoch(punch.clockOut!)
          : null,
    );
  }

  return AttendanceTimeData();
}

String getWorkHours(AttendanceModel a) {
  if (a.worktime != null && a.worktime!.clockOut != null) {
    final diff = a.worktime!.clockOut!.difference(a.worktime!.clockIn);

    return "${diff.inHours}h ${diff.inMinutes.remainder(60)}m";
  }

  return a.formattedWork;
}
