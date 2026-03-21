import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:leadcapture/constants/src/enum.dart';

class AttendanceModel {
  String employeeId;
  List<PunchModel> punchList;
  int breakMinutes;
  String present;
  String holiday;
  String absent;
  int workingHourMinutes;
  int lessHourMinutes;
  int otHourMinutes;
  List<PermissionType> permissions;
  Map<String, PermissionType> permissionDetails;

  AttendanceModel({
    required this.employeeId,
    required this.punchList,
    required this.breakMinutes,
    required this.present,
    required this.holiday,
    required this.absent,
    required this.workingHourMinutes,
    required this.lessHourMinutes,
    required this.otHourMinutes,
    this.permissions = const [],
    this.permissionDetails = const {},
  });

  AttendanceModel copyWith({
    String? employeeId,
    List<PunchModel>? punchList,
    int? breakMinutes,
    String? present,
    String? holiday,
    String? absent,
    int? workingHourMinutes,
    int? lessHourMinutes,
    int? otHourMinutes,
    List<PermissionType>? permissions,
    Map<String, PermissionType>? permissionDetails,
  }) {
    return AttendanceModel(
      employeeId: employeeId ?? this.employeeId,
      punchList: punchList ?? this.punchList,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      present: present ?? this.present,
      holiday: holiday ?? this.holiday,
      absent: absent ?? this.absent,
      workingHourMinutes: workingHourMinutes ?? this.workingHourMinutes,
      lessHourMinutes: lessHourMinutes ?? this.lessHourMinutes,
      otHourMinutes: otHourMinutes ?? this.otHourMinutes,
      permissions: permissions ?? this.permissions,
      permissionDetails: permissionDetails ?? this.permissionDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'employeeId': employeeId,
      'punchList': punchList.map((x) => x.toMap()).toList(),
      'breakMinutes': breakMinutes,
      'present': present,
      'holiday': holiday,
      'absent': absent,
      'workingHourMinutes': workingHourMinutes,
      'lessHourMinutes': lessHourMinutes,
      'otHourMinutes': otHourMinutes,
      'permissions': permissions
          .map((e) => e.toString().split('.').last)
          .toList(),
      'permissionDetails': {
        for (var entry in permissionDetails.entries)
          entry.key: entry.value.toString().split('.').last,
      },
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    final punchRaw = map['punchList'] ?? map['punch_list'];
    List<PermissionType> permissions = [];
    final permissionsRaw = map['permissions'] as List?;
    if (permissionsRaw != null) {
      permissions = permissionsRaw.map<PermissionType>((e) {
        return PermissionType.values.firstWhere(
          (type) => type.toString().split('.').last == e.toString(),
          orElse: () => PermissionType.permission,
        );
      }).toList();
    }

    Map<String, PermissionType> permissionDetails = {};
    final permissionDetailsRaw = map['permissionDetails'] as Map?;
    if (permissionDetailsRaw != null) {
      permissionDetails = {
        for (var entry in permissionDetailsRaw.entries)
          entry.key: PermissionType.values.firstWhere(
            (type) => type.toString().split('.').last == entry.value.toString(),
            orElse: () => PermissionType.permission,
          ),
      };
    }

    return AttendanceModel(
      employeeId: map['employeeId'] ?? '',
      punchList: punchRaw == null
          ? []
          : punchRaw
                .map((e) => PunchModel.fromMap(e as Map<String, dynamic>))
                .toList(),
      breakMinutes: map['breakMinutes'] is int
          ? map['breakMinutes']
          : int.tryParse(map['breakMinutes']?.toString() ?? '0') ?? 0,
      present: map['present']?.toString() ?? '0',
      holiday: map['holiday']?.toString() ?? '0',
      absent: map['absent']?.toString() ?? '0',
      workingHourMinutes: map['working_hour_minutes'] is int
          ? map['working_hour_minutes']
          : int.tryParse(map['working_hour_minutes']?.toString() ?? '0') ?? 0,
      lessHourMinutes: map['less_hour_minutes'] is int
          ? map['less_hour_minutes']
          : int.tryParse(map['less_hour_minutes']?.toString() ?? '0') ?? 0,
      otHourMinutes: map['ot_hour_minutes'] is int
          ? map['ot_hour_minutes']
          : int.tryParse(map['ot_hour_minutes']?.toString() ?? '0') ?? 0,
      permissions: permissions,
      permissionDetails: permissionDetails,
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AttendanceModel(punchList: $punchList, present: $present, holiday: $holiday, absent: $absent, workingHourMinutes: $workingHourMinutes, lessHourMinutes: $lessHourMinutes, otHourMinutes: $otHourMinutes, permissions: $permissions, permissionDetails: $permissionDetails)';
  }

  @override
  bool operator ==(covariant AttendanceModel other) {
    if (identical(this, other)) return true;
    return listEquals(other.punchList, punchList) &&
        other.breakMinutes == breakMinutes &&
        other.present == present &&
        other.holiday == holiday &&
        other.absent == absent &&
        other.workingHourMinutes == workingHourMinutes &&
        other.lessHourMinutes == lessHourMinutes &&
        other.otHourMinutes == otHourMinutes &&
        listEquals(other.permissions, permissions) &&
        mapEquals(other.permissionDetails, permissionDetails);
  }

  @override
  int get hashCode {
    return punchList.hashCode ^
        breakMinutes.hashCode ^
        present.hashCode ^
        holiday.hashCode ^
        absent.hashCode ^
        workingHourMinutes.hashCode ^
        lessHourMinutes.hashCode ^
        otHourMinutes.hashCode ^
        permissions.hashCode ^
        permissionDetails.hashCode;
  }

  // ✅ NEW HELPER METHODS
  bool hasPermission(PermissionType type) {
    return permissions.contains(type);
  }

  bool hasPermissionOnDate(String dateKey, PermissionType type) {
    return permissionDetails[dateKey] == type;
  }

  int permissionCount() {
    return permissions.length;
  }

  List<String> getPermissionDates(PermissionType type) {
    return permissionDetails.entries
        .where((entry) => entry.value == type)
        .map((entry) => entry.key)
        .toList();
  }

  String _formatMinutes(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    return "${h.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}";
  }

  String get formattedWork => _formatMinutes(workingHourMinutes);

  String get formattedLess => _formatMinutes(lessHourMinutes);

  String get formattedOT => _formatMinutes(otHourMinutes);

  String get formattedBreak => _formatMinutes(breakMinutes);
}

class PunchModel {
  String? uid;
  String punchDate;
  List<String> punchTime;
  String totalHours;
  String lessHours;
  String status;
  String day;
  String otHours;
  String otApproval;
  PermissionType? permissionType;
  PermissionsStatus? permissionStatus;

  PunchModel({
    this.uid,
    required this.punchDate,
    required this.punchTime,
    required this.totalHours,
    required this.lessHours,
    required this.status,
    required this.day,
    required this.otHours,
    required this.otApproval,
    this.permissionType,
    this.permissionStatus,
  });

  PunchModel copyWith({
    String? uid,
    String? punchDate,
    List<String>? punchTime,
    String? totalHours,
    String? lessHours,
    String? status,
    String? day,
    String? otHours,
    String? otApproval,
    PermissionType? permissionType,
    PermissionsStatus? permissionStatus,
  }) {
    return PunchModel(
      uid: uid ?? this.uid,
      punchDate: punchDate ?? this.punchDate,
      punchTime: punchTime ?? this.punchTime,
      totalHours: totalHours ?? this.totalHours,
      lessHours: lessHours ?? this.lessHours,
      status: status ?? this.status,
      day: day ?? this.day,
      otHours: otHours ?? this.otHours,
      otApproval: otApproval ?? this.otApproval,
      permissionType: permissionType ?? this.permissionType,
      permissionStatus: permissionStatus ?? this.permissionStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'punchDate': punchDate,
      'punchTime': punchTime,
      'totalHours': totalHours,
      'lessHours': lessHours,
      'status': status,
      'day': day,
      'otHours': otHours,
      'otApproval': otApproval,
      'permissionType': permissionType?.toString().split('.').last,
      'permissionStatus': permissionStatus?.toString().split('.').last,
    };
  }

  factory PunchModel.fromMap(Map<String, dynamic> map) {
    PermissionType? permissionType;

    final permissionRaw = map['permissionType'];

    if (permissionRaw != null) {
      try {
        permissionType = PermissionType.values.firstWhere(
          (type) => type.toString().split('.').last == permissionRaw,
          orElse: () => PermissionType.permission,
        );
      } catch (_) {
        permissionType = null;
      }
    }

    /// Convert minutes → HH:mm if needed
    String minutesToTime(dynamic minutes) {
      if (minutes == null) return '';

      int m = minutes is int ? minutes : int.tryParse(minutes.toString()) ?? 0;

      int h = m ~/ 60;
      int r = m % 60;

      return "${h.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}";
    }

    return PunchModel(
      uid: map['uid'],
      punchDate: map['punchDate'] ?? '',
      punchTime: map['punchTime'] != null
          ? List<String>.from(map['punchTime'].map((e) => e.toString()))
          : [],

      /// Support both formats
      totalHours: map['totalHours'] ?? minutesToTime(map['workingMinutes']),
      lessHours: map['lessHours'] ?? minutesToTime(map['lessMinutes']),
      otHours: map['otHours'] ?? minutesToTime(map['otMinutes']),

      status: map['status'] ?? '',
      day: map['day'] ?? '',
      otApproval: map['otApproval']?.toString() ?? '0',
      permissionType: permissionType,
      permissionStatus: map['permissionStatus'] != null
          ? PermissionsStatus.values.firstWhere(
              (status) =>
                  status.toString().split('.').last ==
                  map['permissionStatus'].toString(),
              orElse: () => PermissionsStatus.pending,
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PunchModel.fromJson(String source) =>
      PunchModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PunchModel(punchDate: $punchDate, punchTime: $punchTime, totalHours: $totalHours, lessHours: $lessHours, status: $status, day: $day, otHours: $otHours, otApproval: $otApproval, permissionType: $permissionType)';
  }

  @override
  bool operator ==(covariant PunchModel other) {
    if (identical(this, other)) return true;
    return other.punchDate == punchDate &&
        listEquals(other.punchTime, punchTime) &&
        other.totalHours == totalHours &&
        other.lessHours == lessHours &&
        other.status == status &&
        other.day == day &&
        other.otHours == otHours &&
        other.otApproval == otApproval &&
        other.permissionType == permissionType;
  }

  @override
  int get hashCode {
    return punchDate.hashCode ^
        punchTime.hashCode ^
        totalHours.hashCode ^
        lessHours.hashCode ^
        status.hashCode ^
        day.hashCode ^
        otHours.hashCode ^
        otApproval.hashCode ^
        permissionType.hashCode;
  }
}

class AttendanceStats {
  final int presentDays;
  final int absentDays;
  final int leaveDays;

  final int wfhDays;
  final int halfDayDays;
  final int lateDays;
  final int earlyExitDays;

  final String totalWorkingHours;
  final String totalLessHours;
  final String totalOTHours;

  final List<AttendanceModel> attendanceData;

  AttendanceStats({
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.wfhDays,
    required this.halfDayDays,
    required this.lateDays,
    required this.earlyExitDays,
    required this.totalWorkingHours,
    required this.totalLessHours,
    required this.totalOTHours,
    required this.attendanceData,
  });

  /// ✅ Deserialize from Map
  factory AttendanceStats.fromMap(Map<String, dynamic> map) {
    return AttendanceStats(
      presentDays: map['presentDays'] is int
          ? map['presentDays'] as int
          : int.tryParse(map['presentDays']?.toString() ?? '0') ?? 0,
      absentDays: map['absentDays'] is int
          ? map['absentDays'] as int
          : int.tryParse(map['absentDays']?.toString() ?? '0') ?? 0,
      leaveDays: map['leaveDays'] is int
          ? map['leaveDays'] as int
          : int.tryParse(map['leaveDays']?.toString() ?? '0') ?? 0,
      wfhDays: map['wfhDays'] is int
          ? map['wfhDays'] as int
          : int.tryParse(map['wfhDays']?.toString() ?? '0') ?? 0,
      halfDayDays: map['halfDayDays'] is int
          ? map['halfDayDays'] as int
          : int.tryParse(map['halfDayDays']?.toString() ?? '0') ?? 0,
      lateDays: map['lateDays'] is int
          ? map['lateDays'] as int
          : int.tryParse(map['lateDays']?.toString() ?? '0') ?? 0,
      earlyExitDays: map['earlyExitDays'] is int
          ? map['earlyExitDays'] as int
          : int.tryParse(map['earlyExitDays']?.toString() ?? '0') ?? 0,
      totalWorkingHours: map['totalWorkingHours']?.toString() ?? '0',
      totalLessHours: map['totalLessHours']?.toString() ?? '0',
      totalOTHours: map['totalOTHours']?.toString() ?? '0',
      attendanceData:
          map['attendanceData'] != null && map['attendanceData'] is List
          ? List<AttendanceModel>.from(
              (map['attendanceData'] as List).map(
                (e) => AttendanceModel.fromMap(e as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  /// ✅ Serialize to Map
  Map<String, dynamic> toMap() {
    return {
      'presentDays': presentDays,
      'absentDays': absentDays,
      'leaveDays': leaveDays,
      'wfhDays': wfhDays,
      'halfDayDays': halfDayDays,
      'lateDays': lateDays,
      'earlyExitDays': earlyExitDays,
      'totalWorkingHours': totalWorkingHours,
      'totalLessHours': totalLessHours,
      'totalOTHours': totalOTHours,
      'attendanceData': attendanceData.map((e) => e.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());
  factory AttendanceStats.fromJson(String source) =>
      AttendanceStats.fromMap(json.decode(source) as Map<String, dynamic>);
}
