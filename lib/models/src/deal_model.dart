import 'dart:convert';
import 'package:flutter/foundation.dart';
import '/models/models.dart';

class DealModel {
  final String? uid;
  final int? dealNumber;
  final String? salutation;
  final String dealName;
  final String dealEmail;
  final double dealValue;
  final bool allowFollowUp;
  final String? dealStatus;
  final List<FileModel> attachments;
  final String notes;
  final String? companyName;
  final String? companyWebsite;
  final String? companyMobile;
  final RegionModel? companyCountry;
  final StateModel? companyState;
  final CityModel? companyCity;
  final String? companyAddress;
  final String? companyZipCode;
  final UserDataModel createdBy;
  final List<String> workFlow;
  final String? clientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DealModel({
    this.uid,
    this.dealNumber,
    this.salutation,
    required this.dealName,
    required this.dealEmail,
    required this.dealValue,
    required this.allowFollowUp,
    this.dealStatus,
    required this.attachments,
    required this.notes,
    this.companyName,
    this.companyWebsite,
    this.companyMobile,
    this.companyCountry,
    this.companyState,
    this.companyCity,
    this.companyAddress,
    this.companyZipCode,
    required this.createdBy,
    this.workFlow = const [],
    this.clientId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  DealModel copyWith({
    String? uid,
    String? dealNumber,
    String? salutation,
    String? dealName,
    String? dealEmail,
    double? dealValue,
    bool? allowFollowUp,
    String? dealStatus,
    List<FileModel>? attachments,
    String? notes,
    String? companyName,
    String? companyWebsite,
    String? companyMobile,
    RegionModel? companyCountry,
    StateModel? companyState,
    CityModel? companyCity,
    String? companyAddress,
    String? companyZipCode,
    UserDataModel? createdBy,
    String? clientId,
    List<String>? workFlow,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealModel(
      uid: uid ?? this.uid,
      dealNumber: dealNumber != null ? int.parse(dealNumber) : this.dealNumber,
      salutation: salutation ?? this.salutation,
      dealName: dealName ?? this.dealName,
      dealEmail: dealEmail ?? this.dealEmail,
      dealValue: dealValue ?? this.dealValue,
      allowFollowUp: allowFollowUp ?? this.allowFollowUp,
      dealStatus: dealStatus ?? this.dealStatus,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      companyName: companyName ?? this.companyName,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyMobile: companyMobile ?? this.companyMobile,
      companyCountry: companyCountry ?? this.companyCountry,
      companyState: companyState ?? this.companyState,
      companyCity: companyCity ?? this.companyCity,
      companyAddress: companyAddress ?? this.companyAddress,
      companyZipCode: companyZipCode ?? this.companyZipCode,
      createdBy: createdBy ?? this.createdBy,
      workFlow: workFlow ?? this.workFlow,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'salutation': salutation,
      'dealName': dealName,
      'dealEmail': dealEmail,
      'dealValue': dealValue,
      'allowFollowUp': allowFollowUp,
      'dealStatus': dealStatus,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'notes': notes,
      'companyName': companyName,
      'companyWebsite': companyWebsite,
      'companyMobile': companyMobile,
      'companyCountry': companyCountry?.toMap(),
      'companyState': companyState?.toMap(),
      'companyCity': companyCity?.toMap(),
      'companyAddress': companyAddress,
      'companyZipCode': companyZipCode,
      'createdBy': createdBy.toMap(),
      'workFlow': workFlow,
      'clientId': clientId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'salutation': salutation,
      'dealName': dealName,
      'dealEmail': dealEmail,
      'dealValue': dealValue,
      'allowFollowUp': allowFollowUp,
      'dealStatus': dealStatus,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'notes': notes,
      'companyName': companyName,
      'companyWebsite': companyWebsite,
      'companyMobile': companyMobile,
      'companyCountry': companyCountry?.toMap(),
      'companyState': companyState?.toMap(),
      'companyCity': companyCity?.toMap(),
      'companyAddress': companyAddress,
      'companyZipCode': companyZipCode,
      'workFlow': workFlow,
      'clientId': clientId,
      'createdBy': createdBy.toMap(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DealModel.fromMap(String uid, Map<String, dynamic> map) {
    return DealModel(
      uid: uid,
      dealNumber: map['dealNumber'] is int
          ? map['dealNumber'] as int
          : int.tryParse(map['dealNumber']?.toString() ?? '0') ?? 0,
      salutation: map['salutation'] != null && map['salutation'] is String
          ? map['salutation'] as String
          : null,
      dealName: map['dealName'] is String ? map['dealName'] as String : '',
      dealEmail: map['dealEmail'] is String ? map['dealEmail'] as String : '',
      dealValue: map['dealValue'] is num
          ? (map['dealValue'] as num).toDouble()
          : double.tryParse(map['dealValue']?.toString() ?? '0') ?? 0.0,
      allowFollowUp: map['allowFollowUp'] is bool
          ? map['allowFollowUp'] as bool
          : false,
      dealStatus: map['dealStatus'] != null && map['dealStatus'] is String
          ? map['dealStatus'] as String
          : null,
      attachments: map['attachments'] != null && map['attachments'] is List
          ? List<FileModel>.from(
              (map['attachments'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map((x) => FileModel.fromMap(x)),
            )
          : [],
      notes: map['notes'] is String ? map['notes'] as String : '',
      companyName: map['companyName'] != null && map['companyName'] is String
          ? map['companyName'] as String
          : null,
      companyWebsite:
          map['companyWebsite'] != null && map['companyWebsite'] is String
          ? map['companyWebsite'] as String
          : null,
      companyMobile:
          map['companyMobile'] != null && map['companyMobile'] is String
          ? map['companyMobile'] as String
          : null,
      companyCountry:
          map['companyCountry'] != null &&
              map['companyCountry'] is Map<String, dynamic>
          ? RegionModel.fromRefMap(
              map['companyCountry'] as Map<String, dynamic>,
            )
          : null,
      companyState:
          map['companyState'] != null &&
              map['companyState'] is Map<String, dynamic>
          ? StateModel.fromMap(map['companyState'] as Map<String, dynamic>)
          : null,
      companyCity:
          map['companyCity'] != null &&
              map['companyCity'] is Map<String, dynamic>
          ? CityModel.fromMap(map['companyCity'] as Map<String, dynamic>)
          : null,
      companyAddress:
          map['companyAddress'] != null && map['companyAddress'] is String
          ? map['companyAddress'] as String
          : null,
      companyZipCode:
          map['companyZipCode'] != null && map['companyZipCode'] is String
          ? map['companyZipCode'] as String
          : null,
      createdBy:
          map['createdBy'] != null && map['createdBy'] is Map<String, dynamic>
          ? UserDataModel.fromMap(map['createdBy'] as Map<String, dynamic>)
          : UserDataModel.fromEmptyMap(),
      workFlow: map['workflow'] != null && map['workflow'] is List
          ? List<String>.from(map['workflow'])
          : [],
      clientId: map['clientId'] != null && map['clientId'] is String
          ? map['clientId'] as String
          : null,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DealModel.fromJson(String uid, String source) =>
      DealModel.fromMap(uid, json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DealModel(uid: $uid, dealNumber: $dealNumber, salutation: $salutation, dealName: $dealName, dealEmail: $dealEmail, dealValue: $dealValue, allowFollowUp: $allowFollowUp, dealStatus: $dealStatus, attachments: $attachments, notes: $notes, companyName: $companyName, companyWebsite: $companyWebsite, companyMobile: $companyMobile, companyCountry: $companyCountry, companyState: $companyState, companyCity: $companyCity, companyAddress: $companyAddress, companyZipCode: $companyZipCode, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant DealModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.dealNumber == dealNumber &&
        other.salutation == salutation &&
        other.dealName == dealName &&
        other.dealEmail == dealEmail &&
        other.dealValue == dealValue &&
        other.allowFollowUp == allowFollowUp &&
        other.dealStatus == dealStatus &&
        listEquals(other.attachments, attachments) &&
        other.notes == notes &&
        other.companyName == companyName &&
        other.companyWebsite == companyWebsite &&
        other.companyMobile == companyMobile &&
        other.companyCountry == companyCountry &&
        other.companyState == companyState &&
        other.companyCity == companyCity &&
        other.companyAddress == companyAddress &&
        other.companyZipCode == companyZipCode &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        dealNumber.hashCode ^
        salutation.hashCode ^
        dealName.hashCode ^
        dealEmail.hashCode ^
        dealValue.hashCode ^
        allowFollowUp.hashCode ^
        dealStatus.hashCode ^
        attachments.hashCode ^
        notes.hashCode ^
        companyName.hashCode ^
        companyWebsite.hashCode ^
        companyMobile.hashCode ^
        companyCountry.hashCode ^
        companyState.hashCode ^
        companyCity.hashCode ^
        companyAddress.hashCode ^
        companyZipCode.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class DealCommentModel {
  final String userId;
  final String comment;
  final DateTime timestamp;

  DealCommentModel({
    required this.userId,
    required this.comment,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  DealCommentModel copyWith({
    String? userId,
    String? comment,
    DateTime? timestamp,
  }) {
    return DealCommentModel(
      userId: userId ?? this.userId,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'comment': comment,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory DealCommentModel.fromMap(Map<String, dynamic> map) =>
      DealCommentModel(
        userId: map['userId'] as String,
        comment: map['comment'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}

class DealHistoryModel {
  final String userId;
  final String updateDisposition;
  final String? update;
  final DateTime timestamp;

  DealHistoryModel({
    required this.userId,
    required this.updateDisposition,
    this.update,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  DealHistoryModel copyWith({
    String? userId,
    String? updateDisposition,
    String? update,
    DateTime? timestamp,
  }) {
    return DealHistoryModel(
      userId: userId ?? this.userId,
      updateDisposition: updateDisposition ?? this.updateDisposition,
      update: update ?? this.update,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'updateDisposition': updateDisposition,
    'update': update,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory DealHistoryModel.fromMap(Map<String, dynamic> map) =>
      DealHistoryModel(
        userId: map['userId'] as String,
        updateDisposition: map['updateDisposition'] as String,
        update: map['update'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}
