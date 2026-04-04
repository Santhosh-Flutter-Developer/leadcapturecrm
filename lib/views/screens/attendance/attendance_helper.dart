import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
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
  int workMinutes = 0;

  if (work.clockOut != null) {
    workMinutes = actualWork;
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

    status: workMinutes >= 480
        ? "Present"
        : workMinutes >= 240
        ? "HalfDay"
        : "Absent",

    day: DateFormat('EEEE').format(work.clockIn),

    otHours: workMinutes > 480 ? formatMinutes(workMinutes - 480) : "0h 0m",

    otApproval: "Pending",
  );

  return AttendanceModel(
    employeeId: work.userUid,
    punchList: [punch],
    breakMinutes: breakMinutes,
    present: "1",
    holiday: "0",
    absent: "0",
    workingHourMinutes: actualWork,
    lessHourMinutes: actualWork < 480 ? 480 - actualWork : 0,
    otHourMinutes: actualWork > 480 ? actualWork - 480 : 0,
  );
}

AttendanceStats calculateStats(List<AttendanceModel> list) {
  int present = 0;
  int absent = 0;
  int leave = 0;
  int wfh = 0;
  int halfDay = 0;
  int late = 0;
  int earlyExit = 0;

  int pending = 0;
  int rejected = 0;
  int permission = 0;
  int inProgress = 0;
  int lessHours = 0;

  for (var a in list) {
    if (a.punchList.isEmpty) {
      absent++;
      continue;
    }

    final status = getAttendanceStatus(a);

    switch (status) {
      case "Present":
        present++;
        break;

      case "Absent":
        absent++;
        break;

      case "Leave":
        leave++;
        break;

      case "WFH":
        wfh++;
        break;

      case "HalfDay":
        halfDay++;
        break;

      case "Late":
        late++;
        break;

      case "EarlyExit":
        earlyExit++;
        break;

      case "Pending":
        pending++;
        break;

      case "Rejected":
        rejected++;
        break;

      case "Permission":
        permission++;
        break;

      case "InProgress":
        inProgress++;
        break;

      case "LessHours":
        lessHours++;
        break;
    }
  }

  return AttendanceStats(
    presentDays: present,
    absentDays: absent,
    leaveDays: leave,
    wfhDays: wfh,
    halfDayDays: halfDay,
    lateDays: late,
    earlyExitDays: earlyExit,

    pendingDays: pending,
    rejectedDays: rejected,
    permissionDays: permission,
    inProgressDays: inProgress,
    lessHoursDays: lessHours,

    totalWorkingHours: "0",
    totalOTHours: "0",
    totalLessHours: "0",

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

String _calculateWorkingStatus(AttendanceModel a) {
  final workedMinutes = a.workingHourMinutes;

  if (workedMinutes == 0) return "Absent";
  if (workedMinutes >= 480) return "Present";
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

class WorkSession {
  final DateTime inTime;
  final DateTime outTime;

  WorkSession({required this.inTime, required this.outTime});
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

List<DataCell> buildSessionCells(List<Session> sessions) {
  List<DataCell> cells = [];
  for (int i = 0; i < 3; i++) {
    if (i < sessions.length) {
      cells.add(
        DataCell(
          Text(
            sessions[i].inTime != null
                ? DateFormat('HH:mm').format(sessions[i].inTime!)
                : "-",
          ),
        ),
      );
      cells.add(
        DataCell(
          Text(
            sessions[i].outTime != null
                ? DateFormat('HH:mm').format(sessions[i].outTime!)
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

  final sortedBreaks = w.breaks.entries.toList()
    ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

  for (var entry in sortedBreaks) {
    final b = entry.value;

    final breakStart = (b['start'] as Timestamp).toDate();
    final breakEnd = (b['end'] as Timestamp).toDate();

    /// Work before break
    sessions.add(Session(inTime: currentIn, outTime: breakStart));

    /// Next session starts after break
    currentIn = breakEnd;
  }

  /// Final session
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
