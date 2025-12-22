import 'dart:convert';
import '/models/models.dart';
import '/utils/utils.dart';

class RoleModel {
  final String? uid;
  final String name;
  final String lowercaseName;
  final String description;
  final List<PermissionModel> permissions;
  final UserDataModel createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoleModel({
    this.uid,
    required this.name,
    String? lowercaseName,
    required this.description,
    this.permissions = const [],
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : lowercaseName = lowercaseName ?? name.toLowerCase(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  RoleModel copyWith({
    String? uid,
    String? name,
    String? lowercaseName,
    String? description,
    List<PermissionModel>? permissions,
    UserDataModel? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      lowercaseName: lowercaseName ?? this.lowercaseName,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name.encrypt,
      'lowercaseName': lowercaseName.encrypt,
      'description': description.encrypt,
      'permissions': permissions.map((e) => e.toMap()).toList(),
      'createdBy': createdBy.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'name': name.encrypt,
      'lowercaseName': lowercaseName.encrypt,
      'description': description.encrypt,
      'permissions': permissions.map((e) => e.toMap()).toList(),
      'createdBy': createdBy.toMap(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory RoleModel.fromMap(String uid, Map<String, dynamic> map) {
    return RoleModel(
      uid: uid,
      name: (map['name'] as String).decrypt,
      lowercaseName: (map['lowercaseName'] as String).decrypt,
      description: (map['description'] as String).decrypt,
      permissions: (map['permissions'] is List)
          ? (map['permissions'] as List)
                .map(
                  (e) => PermissionModel.fromMap(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : [],
      createdBy:
          map['createdBy'] != null && map['createdBy'] is Map<String, dynamic>
          ? UserDataModel.fromMap(map['createdBy'] as Map<String, dynamic>)
          : UserDataModel.fromEmptyMap(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoleModel.fromJson(String uid, String source) =>
      RoleModel.fromMap(uid, json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'RoleModel(uid: $uid, name: $name, lowercaseName: $lowercaseName, description: $description, permissions: $permissions, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant RoleModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.name == name &&
        other.lowercaseName == lowercaseName &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        lowercaseName.hashCode ^
        description.hashCode ^
        permissions.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class PermissionModel {
  final String page;
  bool selectAll;
  bool canCreate;
  bool canEdit;
  bool canDelete;
  bool canView;

  PermissionModel({
    required this.page,
    this.selectAll = false,
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canView = false,
  });

  PermissionModel copyWith({
    String? page,
    bool? selectAll,
    bool? canCreate,
    bool? canEdit,
    bool? canDelete,
    bool? canView,
  }) {
    return PermissionModel(
      page: page ?? this.page,
      selectAll: selectAll ?? this.selectAll,
      canCreate: canCreate ?? this.canCreate,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canView: canView ?? this.canView,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'page': page,
      'selectAll': selectAll,
      'canCreate': canCreate,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canView': canView,
    };
  }

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(
      page: map['page'] as String,
      selectAll: map['selectAll'] as bool,
      canCreate: map['canCreate'] as bool,
      canEdit: map['canEdit'] as bool,
      canDelete: map['canDelete'] as bool,
      canView: map['canView'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory PermissionModel.fromJson(String source) =>
      PermissionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PermissionModel(page: $page, selectAll: $selectAll, canCreate: $canCreate, canEdit: $canEdit, canDelete: $canDelete, canView: $canView)';
  }

  @override
  bool operator ==(covariant PermissionModel other) {
    if (identical(this, other)) return true;

    return other.page == page &&
        other.selectAll == selectAll &&
        other.canCreate == canCreate &&
        other.canEdit == canEdit &&
        other.canDelete == canDelete &&
        other.canView == canView;
  }

  @override
  int get hashCode {
    return page.hashCode ^
        selectAll.hashCode ^
        canCreate.hashCode ^
        canEdit.hashCode ^
        canDelete.hashCode ^
        canView.hashCode;
  }
}
