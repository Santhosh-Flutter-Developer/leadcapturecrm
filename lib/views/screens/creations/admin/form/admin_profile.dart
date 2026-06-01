import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class AdminProfile extends StatefulWidget {
  final AdminModel admin;
  const AdminProfile({super.key, required this.admin});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  PermissionModel? _permissions;
  late AdminModel _admin;

  @override
  void initState() {
    super.initState();
    _admin = widget.admin;
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    _permissions = await PermissionService.getPermissions('Admin');
    if (mounted) setState(() {});
  }

  Future<void> _openEdit() async {
    final uid = _admin.uid;
    if (uid == null || uid.isEmpty) {
      FlushBar.show(
        context,
        'Unable to edit this admin profile',
        isSuccess: false,
      );
      return;
    }

    final result = kIsMobile
        ? await Sheet.showSheet(
            context,
            widget: AdminUpdate(id: uid, admin: _admin),
          )
        : await GeneralDialog.showRTLSheet(
            context,
            AdminUpdate(id: uid, admin: _admin),
          );

    if (result != true) return;

    try {
      final latest = await AdminService.getAdmin(uid: uid);
      if (latest != null && mounted) {
        setState(() {
          _admin = latest;
        });
      }
    } catch (_) {}
  }

  Future<bool> _canEditAdmin() async {
    final currentUid = await Spdb.getUid();
    if (_admin.uid != null && _admin.uid == currentUid) return true;
    return _permissions?.canEdit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canEditAdmin(),
      builder: (context, snapshot) {
        final canEdit = snapshot.data ?? false;

        return Scaffold(
          backgroundColor: AppColors.grey50,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: Back(color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              "Admin Profile",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 1,
              ),
            ),
            actions: [
              IconButton(
                onPressed: canEdit ? _openEdit : null,
                tooltip: canEdit ? 'Edit Admin' : 'No edit permission',
                icon: Icon(
                  Iconsax.edit,
                  color: canEdit
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.grey400,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(context),
                const SizedBox(height: 22),
                _buildDetailsCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: AppColors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.grey300,
              backgroundImage:
                  (_admin.profileImageUrl != null &&
                      _admin.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(_admin.profileImageUrl!)
                  : const NetworkImage(AppStrings.emptyProfilePhotoUrl)
                        as ImageProvider,
            ),

            const SizedBox(height: 20),

            Text(
              _admin.name,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Chip(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              label: Text(
                _admin.isActive ? 'Active' : 'Inactive',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: _admin.isActive
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: AppColors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, "Admin Details"),
            const SizedBox(height: 12),

            _detailRow(
              context: context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: _admin.email,
            ),
            _divider(),

            _detailRow(
              context: context,
              icon: Icons.phone,
              label: 'Mobile Number',
              value: _admin.mobileNumber,
            ),
            _divider(),

            _detailRow(
              context: context,
              icon: Icons.verified_user_outlined,
              label: 'Status',
              value: _admin.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _detailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: AppColors.grey300),
    );
  }
}
