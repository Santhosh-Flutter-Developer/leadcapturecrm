import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/views/screens/attendance/attendance.dart';

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
  if (punch.permissionStatus == PermissionsStatus.pending) return "Pending";
  if (punch.permissionStatus == PermissionsStatus.rejected) return "Rejected";

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
  final workedMinutes = a.workingHourMinutes;
  if (workedMinutes == 0) return "Absent";
  if (workedMinutes >= 480) return "Present";
  if (workedMinutes >= 240) return "HalfDay";
  if (workedMinutes > 0 && workedMinutes < 240) return "LessHours";
  return "Absent";
}
