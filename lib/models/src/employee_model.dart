import 'dart:convert';

import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/admin_model.dart';

import '/utils/utils.dart';
import 'user_data_model.dart';

class EmployeeModel {
  final String? uid;
  final String employeeId;
  final String lowercaseEmployeeId;
  final String name;
  final String email;
  final String password;
  final String designation;
  final List<String>? department;
  final String? subDepartment;
  final String mobileNumber;
  final String? profileImageUrl;
  final String gender;
  final DateTime dateOfJoining;
  final DateTime? dateOfBirth;
  final String role;
  final String address;
  final String about;
  final bool loginAllowed;
  final bool receiveEmailNotifications;
  final String skills;
  final String? employeeType;
  final List<String>? reportingTo;
  final String maritalStatus;
  final bool isActive;
  final DateTime? lastActive;
  final List<Map<String, dynamic>>? devices;
  final bool isInitialPasswordChanged;
  final UserDataModel createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  EmployeeModel({
    this.uid,
    String? lowercaseEmployeeId,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.password,
    required this.designation,
    required this.department,
    this.subDepartment,
    required this.mobileNumber,
    this.profileImageUrl,
    required this.gender,
    required this.dateOfJoining,
    this.dateOfBirth,
    required this.role,
    required this.address,
    required this.about,
    required this.loginAllowed,
    required this.receiveEmailNotifications,
    required this.skills,
    this.employeeType,
    this.reportingTo,
    required this.maritalStatus,
    this.isActive = true,
    this.lastActive,
    this.devices,
    this.isInitialPasswordChanged = false,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : lowercaseEmployeeId = lowercaseEmployeeId ?? employeeId.toLowerCase(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  EmployeeModel copyWith({
    String? uid,
    String? employeeId,
    String? lowercaseEmployeeId,
    String? name,
    String? email,
    String? password,
    String? designation,
    List<String>? department,
    String? subDepartment,
    String? mobileNumber,
    String? profileImageUrl,
    String? gender,
    DateTime? dateOfJoining,
    DateTime? dateOfBirth,
    String? role,
    String? address,
    String? about,
    bool? loginAllowed,
    bool? receiveEmailNotifications,
    String? skills,
    String? employeeType,
    List<String>? reportingTo,
    String? maritalStatus,
    bool? isActive,
    DateTime? lastActive,
    List<Map<String, dynamic>>? devices,
    bool? isInitialPasswordChanged,
    UserDataModel? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      lowercaseEmployeeId: lowercaseEmployeeId ?? this.lowercaseEmployeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      subDepartment: subDepartment ?? this.subDepartment,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      address: address ?? this.address,
      about: about ?? this.about,
      loginAllowed: loginAllowed ?? this.loginAllowed,
      receiveEmailNotifications:
          receiveEmailNotifications ?? this.receiveEmailNotifications,
      skills: skills ?? this.skills,
      employeeType: employeeType ?? this.employeeType,
      reportingTo: reportingTo ?? this.reportingTo,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      isActive: isActive ?? this.isActive,
      lastActive: lastActive ?? this.lastActive,
      devices: devices ?? this.devices,
      isInitialPasswordChanged:
          isInitialPasswordChanged ?? this.isInitialPasswordChanged,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'employeeId': employeeId,
      'lowercaseEmployeeId': lowercaseEmployeeId,
      'name': name.encrypt,
      'email': email.encrypt,
      'password': password.encrypt,
      'designation': designation,
      'department': department,
      'subDepartment': subDepartment,
      'mobileNumber': mobileNumber.encrypt,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'dateOfJoining': dateOfJoining.millisecondsSinceEpoch,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'role': role,
      'address': address.encrypt,
      'about': about.encrypt,
      'loginAllowed': loginAllowed,
      'receiveEmailNotifications': receiveEmailNotifications,
      'skills': skills.encrypt,
      'employeeType': employeeType,
      'reportingTo': reportingTo,
      'maritalStatus': maritalStatus,
      'isActive': isActive,
      'devices': devices,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'isInitialPasswordChanged': isInitialPasswordChanged,
      'createdBy': createdBy.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'employeeId': employeeId,
      'lowercaseEmployeeId': lowercaseEmployeeId,
      'name': name.encrypt,
      'email': email.encrypt,
      'password': password.encrypt,
      'designation': designation,
      'department': department,
      'subDepartment': subDepartment,
      'mobileNumber': mobileNumber.encrypt,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'dateOfJoining': dateOfJoining.millisecondsSinceEpoch,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'role': role,
      'address': address.encrypt,
      'about': about.encrypt,
      'loginAllowed': loginAllowed,
      'receiveEmailNotifications': receiveEmailNotifications,
      'skills': skills.encrypt,
      'employeeType': employeeType,
      'reportingTo': reportingTo,
      'maritalStatus': maritalStatus,
      'isActive': isActive,
      'devices': devices,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'createdBy': createdBy.toMap(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory EmployeeModel.fromMap(String uid, Map<String, dynamic> map) {
    List<String>? parseList(dynamic value) {
      if (value == null) return null;
      if (value is String) return [value];
      if (value is List) return value.map((e) => e.toString()).toList();
      return null;
    }

    return EmployeeModel(
      uid: uid,
      employeeId: map['employeeId'] != null && map['employeeId'] is String
          ? map['employeeId'] as String
          : '',
      lowercaseEmployeeId:
          map['lowercaseEmployeeId'] != null &&
              map['lowercaseEmployeeId'] is String
          ? map['lowercaseEmployeeId'] as String
          : '',
      name: map['name'] != null && map['name'] is String
          ? (map['name'] as String).decrypt
          : '',
      email: map['email'] != null && map['email'] is String
          ? (map['email'] as String).decrypt
          : '',
      password: map['password'] != null && map['password'] is String
          ? (map['password'] as String).decrypt
          : '',
      designation: map['designation'] != null && map['designation'] is String
          ? map['designation'] as String
          : '',
      department: parseList(map['department']),
      subDepartment: map['subDepartment'] as String?,
      mobileNumber: map['mobileNumber'] != null && map['mobileNumber'] is String
          ? (map['mobileNumber'] as String).decrypt
          : '',
      profileImageUrl: map['profileImageUrl'] as String?,
      gender: map['gender'] != null && map['gender'] is String
          ? map['gender'] as String
          : '',
      dateOfJoining: map['dateOfJoining'] != null && map['dateOfJoining'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfJoining'] as int)
          : DateTime.now(),
      dateOfBirth: map['dateOfBirth'] != null && map['dateOfBirth'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] as int)
          : null,
      role: map['role'] != null && map['role'] is String
          ? map['role'] as String
          : '',
      address: map['address'] != null && map['address'] is String
          ? (map['address'] as String).decrypt
          : '',
      about: map['about'] != null && map['about'] is String
          ? (map['about'] as String).decrypt
          : '',
      loginAllowed: map['loginAllowed'] != null && map['loginAllowed'] is bool
          ? map['loginAllowed'] as bool
          : false,
      receiveEmailNotifications:
          map['receiveEmailNotifications'] != null &&
              map['receiveEmailNotifications'] is bool
          ? map['receiveEmailNotifications'] as bool
          : false,
      skills: map['skills'] != null && map['skills'] is String
          ? (map['skills'] as String).decrypt
          : '',
      employeeType: map['employeeType'] as String?,
      reportingTo: parseList(map['reportingTo']),
      maritalStatus:
          map['maritalStatus'] != null && map['maritalStatus'] is String
          ? map['maritalStatus'] as String
          : '',
      isActive: map['isActive'] != null && map['isActive'] is bool
          ? map['isActive'] as bool
          : false,
      isInitialPasswordChanged:
          map['isInitialPasswordChanged'] as bool? ?? false,
      createdBy:
          map['createdBy'] != null && map['createdBy'] is Map<String, dynamic>
          ? UserDataModel.fromMap(map['createdBy'] as Map<String, dynamic>)
          : UserDataModel.fromEmptyMap(),
      createdAt: map['createdAt'] != null && map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory EmployeeModel.fromJson(String uid, String source) =>
      EmployeeModel.fromMap(uid, json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EmployeeModel(..., reportingTo: $reportingTo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class UserRowModel {
  /// Common
  final UserTypes userType;
  final String uid;
  final String name;
  final String email;
  final String mobileNumber;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserDataModel createdBy;
  final List<Map<String, dynamic>>? devices;

  /// Employee-only
  final String? employeeId;
  final String? designation;
  final List<String>? department;
  final String? subDepartment;
  final String? gender;
  final DateTime? dateOfJoining;
  final DateTime? dateOfBirth;
  final String? role;
  final String? address;
  final String? about;
  final bool? loginAllowed;
  final bool? receiveEmailNotifications;
  final String? skills;
  final String? employeeType;
  final List<String>? reportingTo;
  final String? maritalStatus;
  final DateTime? lastActive;
  final bool? isInitialPasswordChanged;

  /// Admin-only
  final String? adminPassword;

  const UserRowModel({
    required this.userType,
    required this.uid,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.profileImageUrl,
    this.devices,

    // employee
    this.employeeId,
    this.designation,
    this.department,
    this.subDepartment,
    this.gender,
    this.dateOfJoining,
    this.dateOfBirth,
    this.role,
    this.address,
    this.about,
    this.loginAllowed,
    this.receiveEmailNotifications,
    this.skills,
    this.employeeType,
    this.reportingTo,
    this.maritalStatus,
    this.lastActive,
    this.isInitialPasswordChanged,

    // admin
    this.adminPassword,
  });

  // ---------------- SAFE GETTERS ----------------

  bool get isEmployee => userType == UserTypes.employee;
  bool get isAdmin => userType == UserTypes.admin;
}

extension EmployeeToRow on EmployeeModel {
  UserRowModel toUserRowModel() {
    return UserRowModel(
      userType: UserTypes.employee,
      uid: uid ?? '',
      employeeId: employeeId,
      name: name,
      email: email,
      mobileNumber: mobileNumber,
      profileImageUrl: profileImageUrl,
      designation: designation,
      department: department,
      subDepartment: subDepartment,
      gender: gender,
      dateOfJoining: dateOfJoining,
      dateOfBirth: dateOfBirth,
      role: role,
      address: address,
      about: about,
      loginAllowed: loginAllowed,
      receiveEmailNotifications: receiveEmailNotifications,
      skills: skills,
      employeeType: employeeType,
      reportingTo: reportingTo,
      maritalStatus: maritalStatus,
      isActive: isActive,
      lastActive: lastActive,
      devices: devices,
      isInitialPasswordChanged: isInitialPasswordChanged,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension AdminToRow on AdminModel {
  UserRowModel toUserRowModel() {
    return UserRowModel(
      userType: UserTypes.admin,
      uid: uid ?? '',
      name: name,
      email: email,
      mobileNumber: mobileNumber,
      profileImageUrl: profileImageUrl,
      adminPassword: password,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension UserRowToEmployee on UserRowModel {
  EmployeeModel toEmployeeModel() {
    assert(userType == UserTypes.employee, 'UserRowModel is not an employee');

    return EmployeeModel(
      uid: uid,
      employeeId: employeeId ?? '',
      name: name,
      email: email,
      password: '', // not available in list
      designation: designation ?? '',
      department: department ?? [],
      subDepartment: subDepartment,
      mobileNumber: mobileNumber,
      profileImageUrl: profileImageUrl,
      gender: gender ?? '',
      dateOfJoining: dateOfJoining ?? DateTime.now(),
      dateOfBirth: dateOfBirth,
      role: role ?? '',
      address: address ?? '',
      about: about ?? '',
      loginAllowed: loginAllowed ?? false,
      receiveEmailNotifications: receiveEmailNotifications ?? false,
      skills: skills ?? '',
      employeeType: employeeType,
      reportingTo: reportingTo,
      maritalStatus: maritalStatus ?? '',
      isActive: isActive,
      lastActive: lastActive,
      devices: devices,
      isInitialPasswordChanged: isInitialPasswordChanged ?? false,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension UserRowToAdmin on UserRowModel {
  AdminModel toAdminModel() {
    assert(userType == UserTypes.admin, 'UserRowModel is not an admin');

    return AdminModel(
      uid: uid,
      name: name,
      email: email,
      password: adminPassword ?? '', // not available in list/edit
      mobileNumber: mobileNumber,
      profileImageUrl: profileImageUrl,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension UserRowActions on UserRowModel {
  bool get isEmployee => userType == UserTypes.employee;
  bool get isAdmin => userType == UserTypes.admin;
}
