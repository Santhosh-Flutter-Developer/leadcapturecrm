class PermissionModel {
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canView;

  PermissionModel({
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canView,
  });

  Map<String, dynamic> toMap() {
    return {
      'canCreate': canCreate,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canView': canView,
    };
  }
}
