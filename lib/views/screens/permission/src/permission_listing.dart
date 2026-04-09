/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/filter_model.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/services/firebase/src/workpermission_service.dart';
import 'package:leadcapture/utils/src/status_color.dart';
import 'package:leadcapture/utils/src/time_format.dart';
import 'package:leadcapture/utils/src/work_permission.dart';
import 'package:leadcapture/views/components/src/sheet.dart';
import 'package:leadcapture/views/screens/permission/src/permisson_create.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/count_display.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/filter.dart';
import 'package:leadcapture/views/ui/src/general_dialog.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

// Project imports:
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';

class PermissionListing extends StatefulWidget {
  const PermissionListing({super.key});

  @override
  State<PermissionListing> createState() => _PermissionListingState();
}

const String _pageTitle = "Permission Request";

class _PermissionListingState extends State<PermissionListing> {
  late Future _pHandler;
  FilterModel _filter = FilterModel(pageLimit: 10, pageNumber: 1);
  int _pCount = 0;
  List<WorkPermissionModel> _rList = [];
  final List<WorkPermissionModel> _tempRList = [];
  // final TextEditingController _search = TextEditingController();
  // final bool _searchApplied = false;

  @override
  void initState() {
    _pHandler = _init();
    super.initState();
  }

  Future<void> _init() async {
    _rList.clear();
    _tempRList.clear();

    _pCount = await WorkPermissionService.permissionsCount();
    _rList = await WorkPermissionService.permissionListing(filter: _filter);

    _rList.sort((a, b) => b.created.compareTo(a.created));
    _tempRList.addAll(_rList);
  }

  Color _statusBadgeColor(PermissionsStatus status) {
    switch (status) {
      case PermissionsStatus.pending:
        return Colors.orange.shade100;
      case PermissionsStatus.approved:
        return Colors.green.shade100;
      case PermissionsStatus.rejected:
        return Colors.red.shade100;
    }
  }

  Color _statusTextColor(PermissionsStatus status) {
    switch (status) {
      case PermissionsStatus.pending:
        return Colors.orange.shade800;
      case PermissionsStatus.approved:
        return Colors.green.shade800;
      case PermissionsStatus.rejected:
        return Colors.red.shade800;
    }
  }

  // void _searchPermission() {
  //   final filtered = _tempRList.where((p) {
  //     return p.userName.toLowerCase().contains(_search.text.toLowerCase());
  //   }).toList();
  //   setState(() => _rList = filtered);
  // }

  String _permissionType(WorkPermissionModel model) {
    if (model.type == PermissionType.leaveHalfDay && model.session != null) {
      return "${model.type.label} "
          "(${model.session == HalfDaySession.morning ? "Morning" : "Afternoon"})";
    }
    return model.type.label;
  }

  bool _showDuration(WorkPermissionModel p) {
    return !(p.type == PermissionType.leaveFullDay ||
        p.type == PermissionType.workFromHome);
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  void _openSheet(BuildContext context, Widget widget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (kIsMobile) {
        Sheet.showSheet(context, widget: widget);
      } else {
        GeneralDialog.showRTLSheet(context, widget);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ADD
          FloatingActionButton(
            heroTag: "addPermission",
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.pureWhiteColor,
            tooltip: "Add",
            child: const Icon(Iconsax.add),
            onPressed: () async {
              _openSheet(context, const PermissonCreate());
            },
          ),

          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "filterPermission",
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.pureWhiteColor,
            tooltip: "Filter",
            child: const Icon(Iconsax.filter),
            onPressed: () async {
              var v = await Sheet.showSheet(
                context,
                size: 0.9,
                widget: Filter(filter: _filter, totalCount: _pCount),
              );

              if (v != null) {
                _filter = v;
                _pHandler = _init();
                setState(() {});
              }
            },
          ),
        ],
      ),
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          _pHandler = _init();
          setState(() {});
        },
        child: FutureBuilder(
          future: _pHandler,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else if (_rList.isEmpty) {
              return const NoData();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CountDisplay(
                  pageLimit: _filter.pageLimit,
                  pageNumber: _filter.pageNumber,
                  totalCount: _pCount,
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rList.length,
                  itemBuilder: (context, index) {
                    final p = _rList[index];
                    // final duration = getDurationDates(p.from, p.to);

                    return GestureDetector(
                      onTap: () async {
                        await Sheet.showSheet(
                          context,
                          size: 0.3,
                          widget: PermissionStatusDisplay(permission: p),
                        );
                      },
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _statusBadgeColor(
                              p.status,
                            ).withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        color: Theme.of(context).cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: _statusBadgeColor(p.status),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _permissionType(p),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .primaryColor,
                                                    ),
                                              ),

                                              // Separator
                                              const TextSpan(
                                                text: "  •  ",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),

                                              // Reason
                                              TextSpan(
                                                text: p.reason.isNotEmpty
                                                    ? p.reason
                                                    : 'No reason provided',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: p.reason.isNotEmpty
                                                          ? Colors.grey[700]
                                                          : Colors.grey[400],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusBadgeColor(
                                            p.status,
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _statusBadgeColor(
                                              p.status,
                                            ).withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          p.status.name.capitalizeFirst,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: _statusTextColor(
                                                  p.status,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      if (_showDuration(p)) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Iconsax.clock,
                                                size: 11,
                                                color: Colors.green[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(
                                                  getDurationDates(
                                                    p.from,
                                                    p.to,
                                                  ),
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors.green[700],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                      ] else
                                        const Spacer(),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          /// 📅 DATE BADGE
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  DateFormat(
                                                    'MMM',
                                                  ).format(p.created),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.blue[400],
                                                        letterSpacing: 0.5,
                                                        height: 1.2,
                                                      ),
                                                ),
                                                Text(
                                                  DateFormat(
                                                    'dd',
                                                  ).format(p.created),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue[700],
                                                        height: 1.1,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          /// ⏱ TIME AGO (keep this separate for clarity)
                                          Text(
                                            timeago(p.modified),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color: AppColors.greyColor,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Divider(color: Colors.grey[200], height: 0.5),
                                  const SizedBox(height: 3),
                                  if (p.withSalary ||
                                      p.approvedBy != null ||
                                      p.approvedAt != null) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if (p.withSalary)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.attach_money_rounded,
                                                  size: 12,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'With Salary',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: Colors.blue[700],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        if (p.approvedBy != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                p.approvedBy!,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),

                                        if (p.approvedAt != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.event_available_rounded,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                DateFormat(
                                                  'MMM dd',
                                                ).format(p.approvedAt!),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PermissionStatusDisplay extends StatelessWidget {
  final WorkPermissionModel permission;
  const PermissionStatusDisplay({super.key, required this.permission});

  String _permissionTypeText() {
    if (permission.type == PermissionType.leaveHalfDay &&
        permission.session != null) {
      return "${permission.type.label} (${permission.session == HalfDaySession.morning ? "Morning" : "Afternoon"})";
    }
    return permission.type.label;
  }

  Color _statusBadgeColor() {
    switch (permission.status) {
      case PermissionsStatus.pending:
        return Colors.orange.shade100;
      case PermissionsStatus.approved:
        return Colors.green.shade100;
      case PermissionsStatus.rejected:
        return Colors.red.shade100;
    }
  }

  Color _statusTextColor() {
    switch (permission.status) {
      case PermissionsStatus.pending:
        return Colors.orange.shade800;
      case PermissionsStatus.approved:
        return Colors.green.shade800;
      case PermissionsStatus.rejected:
        return Colors.red.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhiteColor,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Text(
                "Permission Status",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Status Row
              Row(
                children: [
                  Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      color: getStatusColor(permission.status.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    permission.status.name.capitalizeFirst,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBadgeColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _permissionTypeText(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _statusTextColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Requested On
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    "Requested on ${permission.created.formatDateTime}",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (permission.reason.isNotEmpty) ...[
                Text(
                  "Reason",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  permission.reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              // Message
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _statusBadgeColor(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  permission.status == PermissionsStatus.pending
                      ? "Please wait, your permission is pending..."
                      : permission.status == PermissionsStatus.rejected
                      ? "Your permission is rejected"
                      : "Your permission is accepted",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _statusTextColor(),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
