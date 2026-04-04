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

  Map<String, dynamic> toUpdateMap({bool updatePassword = false}) {
    return {
      'name': name.encrypt,
      'email': email.encrypt,
      if (updatePassword) 'password': password.encrypt,
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
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory EmployeeModel.fromMap(String uid, Map<String, dynamic> map) {
    List<String>? parseList(dynamic value) {
      if (value == null) return null;
      if (value is String) return [value];
      if (value is List) return value.map((e) => e.toString()).toList();
      return null;
    }

    List<Map<String, dynamic>>? parseDevices(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return null;
    }

    return EmployeeModel(
      uid: uid,
      employeeId: map['employeeId'] ?? '',
      lowercaseEmployeeId: map['lowercaseEmployeeId'] ?? '',
      name: (map['name'] ?? '').toString().decrypt,
      email: (map['email'] ?? '').toString().decrypt,
      password: (map['password'] ?? '').toString().decrypt,
      designation: map['designation'] ?? '',
      department: parseList(map['department']),
      subDepartment: map['subDepartment'],
      mobileNumber: (map['mobileNumber'] ?? '').toString().decrypt,
      profileImageUrl: map['profileImageUrl'],
      gender: map['gender'] ?? '',
      dateOfJoining: map['dateOfJoining'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfJoining'])
          : DateTime.now(),
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : null,
      role: map['role'] ?? '',
      address: (map['address'] ?? '').toString().decrypt,
      about: (map['about'] ?? '').toString().decrypt,
      loginAllowed: map['loginAllowed'] ?? false,
      receiveEmailNotifications: map['receiveEmailNotifications'] ?? false,
      skills: (map['skills'] ?? '').toString().decrypt,
      employeeType: map['employeeType'],
      reportingTo: parseList(map['reportingTo']),
      maritalStatus: map['maritalStatus'] ?? '',
      isActive: map['isActive'] ?? true,
      lastActive: map['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'])
          : null,
      devices: parseDevices(map['devices']),
      isInitialPasswordChanged: map['isInitialPasswordChanged'] ?? false,
      createdBy: map['createdBy'] != null
          ? UserDataModel.fromMap(map['createdBy'])
          : UserDataModel.fromEmptyMap(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
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
  final UserType userType;
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

  bool get isEmployee => userType == UserType.employee;
  bool get isAdmin => userType == UserType.admin;
}

extension EmployeeToRow on EmployeeModel {
  UserRowModel toUserRowModel() {
    return UserRowModel(
      userType: UserType.employee,
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
      userType: UserType.admin,
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
      devices: devices,
    );
  }
}

extension UserRowToEmployee on UserRowModel {
  EmployeeModel toEmployeeModel() {
    assert(userType == UserType.employee, 'UserRowModel is not an employee');

    return EmployeeModel(
      uid: uid,
      employeeId: employeeId ?? '',
      name: name,
      email: email,
      password: '',
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
    assert(userType == UserType.admin, 'UserRowModel is not an admin');

    return AdminModel(
      uid: uid,
      name: name,
      email: email,
      password: adminPassword ?? '',
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
  bool get isEmployee => userType == UserType.employee;
  bool get isAdmin => userType == UserType.admin;
}
