import 'package:flutter/material.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';
import '/views/views.dart';

class AdminProfile extends StatelessWidget {
  final AdminModel admin;
  const AdminProfile({super.key, required this.admin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: FormWidgets.buildHeader(context: context, title: "Admin Profile"),

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
                  (admin.profileImageUrl != null &&
                      admin.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(admin.profileImageUrl!)
                  : const NetworkImage(AppStrings.emptyProfilePhotoUrl)
                        as ImageProvider,
            ),

            const SizedBox(height: 20),

            Text(
              admin.name,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Chip(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              label: Text(
                admin.isActive ? "Active" : "Inactive",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: admin.isActive
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
              label: "Email",
              value: admin.email,
            ),
            _divider(),

            _detailRow(
              context: context,
              icon: Icons.phone,
              label: "Mobile Number",
              value: admin.mobileNumber,
            ),
            _divider(),

            _detailRow(
              context: context,
              icon: Icons.verified_user_outlined,
              label: "Status",
              value: admin.isActive ? "Active" : "Inactive",
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
