/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/services/firebase/src/workpermission_service.dart';
import 'package:leadcapture/utils/src/work_permission.dart';
import 'package:leadcapture/views/screens/permission/src/permission_approval.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

// Project imports:
import '/theme/theme.dart';
import '/utils/utils.dart';

class PermissonView extends StatefulWidget {
  final String id;
  const PermissonView({super.key, required this.id});

  @override
  State<PermissonView> createState() => _PermissonViewState();
}

class _PermissonViewState extends State<PermissonView> {
  late Future<WorkPermissionModel?> _handler;
  WorkPermissionModel? model;

  @override
  void initState() {
    super.initState();
    _handler = _init();
  }

  Future<WorkPermissionModel?> _init() async {
    model = await WorkPermissionService.getPermission(id: widget.id);
    setState(() {});
    return model;
  }

  String _getDurationString(WorkPermissionModel model) {
    final duration = model.to.difference(model.from);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours hrs $minutes mins';
  }

  String _getSessionText(HalfDaySession? session) {
    if (session == null) return '';
    return session == HalfDaySession.morning
        ? 'Morning (First Half)'
        : 'Afternoon (Second Half)';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkPermissionModel?>(
      future: _handler,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WaitingLoading();
        }

        if (snapshot.hasError) {
          return ErrorDisplay(error: snapshot.error.toString());
        }

        final model = snapshot.data!;

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              leading: const Back(),
              title: const Text("Permission Details"),
              //   backgroundColor: Colors.white,
              //   foregroundColor: Colors.black87,
              //   elevation: 0.5,
            ),
            bottomNavigationBar: model.status == PermissionsStatus.pending
                ? SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black12,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PermissionApproval(model: model),
                            ),
                          );

                          if (result == true) {
                            _handler = _init();
                            setState(() {});
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Iconsax.edit, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Take Action",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.1),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getStatusColor(model.status),
                                child: Icon(
                                  _getStatusIcon(model.status),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      model.userName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      model.status.name.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(model.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _info("Type", model.type.label, isBold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// DETAILS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Basic Information"),
                          _info("Employee", model.userName),
                          _info("Reason", model.reason),
                          _info("Date", model.date.formatDate),

                          if (model.type == PermissionType.leaveHalfDay)
                            _info("Session", _getSessionText(model.session)),

                          _info("Duration", _getDurationString(model)),
                          _info("From", model.from.formatDateTime),
                          _info("To", model.to.formatDateTime),

                          _info(
                            "Created",
                            model.created.formatDateTime,
                            isSecondary: true,
                          ),
                          _info(
                            "Modified",
                            model.modified.formatDateTime,
                            isSecondary: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(PermissionsStatus status) {
    switch (status) {
      case PermissionsStatus.approved:
        return AppColors.greenColor;
      case PermissionsStatus.rejected:
        return AppColors.redColor;
      case PermissionsStatus.pending:
        return Colors.amber.shade700;
    }
  }

  IconData _getStatusIcon(PermissionsStatus status) {
    switch (status) {
      case PermissionsStatus.approved:
        return Icons.offline_pin_rounded;
      case PermissionsStatus.rejected:
        return Icons.report_problem_rounded;
      case PermissionsStatus.pending:
        return Icons.pending_actions_rounded;
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _info(
    String label,
    String value, {
    bool isBold = false,
    bool isSecondary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isSecondary ? Colors.grey[600] : null,
          ),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: AppColors.primaryColor,
                fontSize: 15,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
