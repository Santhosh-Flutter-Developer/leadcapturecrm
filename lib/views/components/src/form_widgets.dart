import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/theme/theme.dart';

class FormWidgets {
  static PreferredSizeWidget buildHeader({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 1.0,
      shadowColor: AppColors.black12,
      automaticallyImplyLeading: false,
      foregroundColor: AppColors.black,
      centerTitle: false,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  static Widget buildBottomBar({
    required BuildContext context,
    required VoidCallback onSubmit,
    bool isEdit = false,
    String cancelText = "Cancel",
    IconData cancelIcon = Icons.close_rounded,
    IconData createIcon = Icons.add_rounded,
    IconData editIcon = Iconsax.edit,
  }) {
    final submitText = isEdit ? "Update" : "Create";
    final submitIcon = isEdit ? editIcon : createIcon;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Cancel Button
          ElevatedButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.grey100,
              foregroundColor: AppColors.grey800,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.grey300),
              ),
            ),
            child: Row(
              children: [
                Icon(cancelIcon, size: 18),
                const SizedBox(width: 6),
                Text(
                  cancelText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Submit Button (Create or Update)
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              elevation: 2,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(submitIcon, size: 20),
                const SizedBox(width: 6),
                Text(
                  submitText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
