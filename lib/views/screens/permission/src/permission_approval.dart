/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/services/firebase/src/workpermission_service.dart';
import 'package:leadcapture/theme/src/app_colors.dart';
import 'package:leadcapture/utils/src/extensions.dart';
import 'package:leadcapture/utils/src/work_permission.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:leadcapture/views/ui/src/snackbar.dart';

class PermissionApproval extends StatefulWidget {
  final WorkPermissionModel? model;
  const PermissionApproval({super.key, this.model});

  @override
  State<PermissionApproval> createState() => _PermissionApprovalState();
}

class _PermissionApprovalState extends State<PermissionApproval> {
  bool withSalary = true;
  WorkPermissionModel? model;

  @override
  void initState() {
    super.initState();
    model = widget.model;
  }

  String _getDurationString() {
    final duration = model!.to.difference(model!.from);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours hrs $minutes mins';
  }

  String _getSessionText() {
    if (model!.type != PermissionType.leaveHalfDay || model!.session == null) {
      return '';
    }
    return model!.session == HalfDaySession.morning
        ? 'Morning (First Half)'
        : 'Afternoon (Second Half)';
  }

  Future<void> _rejectPermission() async {
    try {
      futureLoading(context);

      await WorkPermissionService.approveOrRejectPermission(
        status: PermissionsStatus.rejected,
        withSalary: false,
        uid: model!.uid,
      );

      Navigator.pop(context);
      Snackbar.showSnackBar(
        context,
        content: "Permission rejected successfully",
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context);
      Snackbar.showSnackBar(context, content: e.toString(), isSuccess: false);
    }
  }

  Future<void> _approvePermission() async {
    try {
      futureLoading(context);

      await WorkPermissionService.approveOrRejectPermission(
        status: PermissionsStatus.approved,
        withSalary: withSalary,
        uid: model!.uid,
      );

      Navigator.pop(context);
      Snackbar.showSnackBar(
        context,
        content:
            "Permission ${withSalary ? 'approved with salary' : 'approved without salary'} successfully",
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context);
      Snackbar.showSnackBar(context, content: e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: const Back(),
        title: const Text(
          "Permission Approval",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        // backgroundColor: Colors.white,
        // foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// HEADER CARD WITH EMPLOYEE & STATUS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.1),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.08),
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.amber.shade100,
                                child: const Icon(
                                  Iconsax.user,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      model!.userName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                    ),
                                    Text(
                                      "Pending Approval",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _info("Type", model!.type.label, isBold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// DETAILS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.08),
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Request Details"),
                          _info("Reason", model!.reason),
                          _info("Date", model!.date.formatDate),

                          if (model!.type == PermissionType.leaveHalfDay)
                            _info("Session", _getSessionText()),

                          _info("Duration", _getDurationString()),
                          _info("From", model!.from.formatDateTime),
                          _info("To", model!.to.formatDateTime),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// SALARY OPTION CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.08),
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Salary Option"),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              "Approve With Salary",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              withSalary
                                  ? "Employee will receive full salary"
                                  : "Salary will be deducted for this duration",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: withSalary,
                            activeThumbColor: AppColors.primaryColor,
                            onChanged: (v) => setState(() => withSalary = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons (Fixed height)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Iconsax.close_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Reject",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _rejectPermission,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Iconsax.tick_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Approve",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _approvePermission,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: AppColors.primaryColor,
                fontSize: 15,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
