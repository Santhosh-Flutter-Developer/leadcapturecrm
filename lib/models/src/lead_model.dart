// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import '/models/models.dart';

class LeadModel {
  final String? uid;
  final int? leadNumber;
  final String? salutation;
  final String leadName;
  final String leadEmail;
  final LeadSourceModel leadSource;
  final String leadCategory;
  final double leadValue;
  final bool allowFollowUp;
  final String leadStatus;
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
  final List<String> workflow;
  final String? clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool leadsConverted;
  final String? dealId;

  LeadModel({
    this.uid,
    this.leadNumber,
    this.salutation,
    required this.leadName,
    required this.leadEmail,
    required this.leadSource,
    required this.leadCategory,
    required this.leadValue,
    required this.allowFollowUp,
    required this.leadStatus,
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
    this.workflow = const [],
    this.clientId,
    this.dealId,
    this.leadsConverted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  LeadModel copyWith({
    String? uid,
    int? leadNumber,
    String? salutation,
    String? leadName,
    String? leadEmail,
    LeadSourceModel? leadSource,
    String? leadCategory,
    double? leadValue,
    bool? allowFollowUp,
    String? leadStatus,
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
    List<String>? workflow,
    String? clientId,
    UserDataModel? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? leadsConverted,
    String? dealId,
  }) {
    return LeadModel(
      uid: uid ?? this.uid,
      leadNumber: leadNumber ?? this.leadNumber,
      salutation: salutation ?? this.salutation,
      leadName: leadName ?? this.leadName,
      leadEmail: leadEmail ?? this.leadEmail,
      leadSource: leadSource ?? this.leadSource,
      leadCategory: leadCategory ?? this.leadCategory,
      leadValue: leadValue ?? this.leadValue,
      allowFollowUp: allowFollowUp ?? this.allowFollowUp,
      leadStatus: leadStatus ?? this.leadStatus,
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
      workflow: workflow ?? this.workflow,
      clientId: clientId ?? this.clientId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      leadsConverted: leadsConverted ?? this.leadsConverted,
      dealId: dealId ?? this.dealId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salutation': salutation,
      'leadName': leadName,
      'leadEmail': leadEmail,
      'leadSource': leadSource.toStoreMap(),
      'leadCategory': leadCategory,
      'leadValue': leadValue,
      'allowFollowUp': allowFollowUp,
      'leadStatus': leadStatus,
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
      'workflow': workflow,
      'clientId': clientId,
      'createdBy': createdBy.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'leadsConverted': leadsConverted,
      'dealId': dealId,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'salutation': salutation,
      'leadName': leadName,
      'leadEmail': leadEmail,
      'leadSource': leadSource.toStoreMap(),
      'leadCategory': leadCategory,
      'leadValue': leadValue,
      'allowFollowUp': allowFollowUp,
      'leadStatus': leadStatus,
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
      'workflow': workflow,
      'clientId': clientId,
      'createdBy': createdBy.toMap(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'leadsConverted': leadsConverted,
    };
  }

  factory LeadModel.fromMap(String uid, Map<String, dynamic> map) {
    return LeadModel(
      uid: uid,
      leadNumber: map['leadNumber'] is int
          ? map['leadNumber'] as int
          : int.tryParse(map['leadNumber']?.toString() ?? ''),
      salutation: map['salutation'] != null && map['salutation'] is String
          ? map['salutation'] as String
          : null,
      leadName: map['leadName'] is String ? map['leadName'] as String : '',
      leadEmail: map['leadEmail'] is String ? map['leadEmail'] as String : '',
      leadSource:
          map['leadSource'] != null && map['leadSource'] is Map<String, dynamic>
          ? LeadSourceModel.fromMap(
              map['leadSource']['uid'],
              map['leadSource'] as Map<String, dynamic>,
            )
          : LeadSourceModel.fromEmptyMap(),
      leadCategory: map['leadCategory'] is String
          ? map['leadCategory'] as String
          : '',
      leadStatus: map['leadStatus'] is String
          ? map['leadStatus'] as String
          : '',
      leadValue: map['leadValue'] is num
          ? (map['leadValue'] as num).toDouble()
          : double.tryParse(map['leadValue']?.toString() ?? '0') ?? 0.0,
      allowFollowUp: map['allowFollowUp'] is bool
          ? map['allowFollowUp'] as bool
          : false,
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
      workflow: map['workflow'] != null && map['workflow'] is List
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
      leadsConverted:
          map['leadsConverted'] != null && map['leadsConverted'] is bool
          ? map['leadsConverted'] as bool
          : false,
    );
  }

  String toJson() => json.encode(toMap());

  factory LeadModel.fromJson(String uid, String source) =>
      LeadModel.fromMap(uid, json.decode(source));

  @override
  String toString() =>
      'LeadModel(uid: $uid, leadName: $leadName, leadEmail: $leadEmail, leadCategory: $leadCategory, leadStatus: $leadStatus)';

  @override
  bool operator ==(covariant LeadModel other) {
    if (identical(this, other)) return true;
    return other.uid == uid &&
        other.leadName == leadName &&
        other.leadEmail == leadEmail &&
        other.leadCategory == leadCategory &&
        other.leadStatus == leadStatus;
  }

  @override
  int get hashCode =>
      Object.hash(uid, leadName, leadEmail, leadCategory, leadStatus);
}
