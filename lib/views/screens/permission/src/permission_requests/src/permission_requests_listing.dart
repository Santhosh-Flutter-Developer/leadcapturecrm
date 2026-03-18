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
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/filter_model.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/services/firebase/src/workpermission_service.dart';
import 'package:leadcapture/utils/src/status_color.dart';
import 'package:leadcapture/utils/src/time_format.dart';
import 'package:leadcapture/utils/src/work_permission.dart';
import 'package:leadcapture/views/components/src/sheet.dart';
import 'package:leadcapture/views/screens/permission/src/permission_requests/src/permission_requests_view.dart';
import 'package:leadcapture/views/ui/src/appbar.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/count_display.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/filter.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

// Project imports:
import '/theme/theme.dart';
import '/utils/utils.dart';

class PermissionRequestsListing extends StatefulWidget {
  const PermissionRequestsListing({super.key});

  @override
  State<PermissionRequestsListing> createState() =>
      _PermissionRequestsListingState();
}

class _PermissionRequestsListingState extends State<PermissionRequestsListing> {
  late Future _pHanlder;
  FilterModel _filter = FilterModel(pageLimit: 10, pageNumber: 1);
  int _pCount = 0;
  List<WorkPermissionModel> _rList = [];
  final List<WorkPermissionModel> _tempRList = [];

  String _permissionTypeText(WorkPermissionModel model) {
    if (model.type == PermissionType.leaveHalfDay && model.session != null) {
      return "${model.type.label} "
          "(${model.session == HalfDaySession.morning ? "Morning" : "Afternoon"})";
    }
    return model.type.label;
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  void initState() {
    _pHanlder = _init();
    super.initState();
  }

  _init() async {
    _rList.clear();
    _tempRList.clear();

    _pCount = await WorkPermissionService.permissionRequestCount();

    _rList = await WorkPermissionService.permissionRequestListing(
      filter: _filter,
    );

    _rList.sort((a, b) => b.created.compareTo(a.created));
    _tempRList.addAll(_rList);
  }

  bool _searchApplied = false;
  _searchPermission() {
    List<WorkPermissionModel> filteredList = _tempRList.where((payments) {
      return payments.userName.toString().toLowerCase().contains(
        _search.text.toLowerCase(),
      );
    }).toList();

    setState(() {
      _rList = filteredList;
    });
  }

  final TextEditingController _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        foregroundColor: AppColors.whiteColor,
        backgroundColor: AppColors.primaryColor,
        shape: const CircleBorder(),
        onPressed: () async {
          var v = await Sheet.showSheet(
            context,
            size: 0.9,
            widget: Filter(filter: _filter, totalCount: _pCount),
          );
          if (v != null) {
            _filter = v;
            _pHanlder = _init();
            setState(() {});
          }
        },
        child: const Icon(Iconsax.filter),
      ),
      appBar: Appbar(
        searchApplied: _searchApplied,
        search: _search,
        backPress: () {
          _searchApplied = false;
          setState(() {});
        },
        onChanged: (value) => _searchPermission(),
        leading: const Back(),
        nonSearchTitle: const Text("Permission Requests"),
        searchHintText: "Search by name...",
        actions: [
          IconButton(
            tooltip: "Search",
            icon: const Icon(Iconsax.search_normal),
            onPressed: () {
              setState(() {
                _searchApplied = true;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _pHanlder = _init();
          setState(() {});
        },
        child: FutureBuilder(
          future: _pHanlder,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              if (_rList.isNotEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CountDisplay(
                      pageLimit: _filter.pageLimit,
                      pageNumber: _filter.pageNumber,
                      totalCount: _pCount,
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      primary: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _rList.length,
                      itemBuilder: (context, index) {
                        final permission = _rList[index];
                        final duration = getDurationDates(
                          permission.from,
                          permission.to,
                        );

                        return GestureDetector(
                          onTap: () async {
                            var result = await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    PermissonView(id: permission.uid),
                              ),
                            );
                            if (result != null && result == true) {
                              _pHanlder = _init();
                              setState(() {});
                            }
                          },
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: getStatusColor(
                                  permission.status.name,
                                ).withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            color: Theme.of(context).cardColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ─── Colored Top Strip ───────────────────────────────────────────
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: getStatusColor(
                                      permission.status.name,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    14,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ─── Serial Number Circle ────────────────────────────────
                                      Container(
                                        height: 34,
                                        width: 34,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryColor
                                                  .withOpacity(0.75),
                                              AppColors.primaryColor,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            (index + 1).toString().padLeft(
                                              2,
                                              '0',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // ─── Main Content ────────────────────────────────────────
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Row 1: Name + Status indicator
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _rList[index].userName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Status dot + label
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 9,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: getStatusColor(
                                                      permission.status.name,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: getStatusColor(
                                                        permission.status.name,
                                                      ).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 7,
                                                        height: 7,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  getStatusColor(
                                                                    permission
                                                                        .status
                                                                        .name,
                                                                  ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        permission
                                                            .status
                                                            .name
                                                            .capitalizeFirst,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  getStatusColor(
                                                                    permission
                                                                        .status
                                                                        .name,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  0.3,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            // Permission Type Chip
                                            // Row / Wrap for Permission Type + Chips
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                // Permission Type badge
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppColors.primaryColor
                                                            .withOpacity(0.1),
                                                        AppColors.primaryColor
                                                            .withOpacity(0.05),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors
                                                          .primaryColor
                                                          .withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _permissionTypeText(
                                                      permission,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .primaryColor,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.2,
                                                        ),
                                                  ),
                                                ),

                                                // With Salary chip
                                                if (permission.withSalary)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.blue
                                                            .withOpacity(0.25),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .attach_money_rounded,
                                                          size: 13,
                                                          color:
                                                              Colors.blue[700],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'With Salary',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .blue[700],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                // Approved by chip
                                                if (permission.approvedBy !=
                                                    null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.green
                                                            .withOpacity(0.25),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 13,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          permission
                                                              .approvedBy!,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .green[700],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                // Approved at chip
                                                if (permission.approvedAt !=
                                                    null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.orange
                                                            .withOpacity(0.25),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 13,
                                                          color: Colors
                                                              .orange[700],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          DateFormat(
                                                            'MMM dd, yyyy',
                                                          ).format(
                                                            permission
                                                                .approvedAt!,
                                                          ),
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .orange[700],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            // ─── Duration + Date Row ────────────────────────────
                                            Row(
                                              children: [
                                                // Duration pill
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Iconsax.clock,
                                                        size: 13,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatDuration(
                                                          duration,
                                                        ),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: Colors
                                                                  .green[700],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const Spacer(),

                                                // Date badge (calendar-style)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.blue
                                                          .withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        DateFormat(
                                                          'MMM',
                                                        ).format(
                                                          permission.created,
                                                        ),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Colors
                                                                  .blue[400],
                                                              letterSpacing:
                                                                  0.5,
                                                              height: 1.2,
                                                            ),
                                                      ),
                                                      Text(
                                                        DateFormat('dd').format(
                                                          permission.created,
                                                        ),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .blue[700],
                                                              height: 1.1,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            Divider(
                                              color: Colors.grey[200],
                                              height: 1,
                                            ),

                                            const SizedBox(height: 8),

                                            // ─── Reason + timeago ───────────────────────────────
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.notes_rounded,
                                                  size: 14,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    permission.reason.isNotEmpty
                                                        ? permission.reason
                                                        : 'No reason provided',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              permission
                                                                  .reason
                                                                  .isNotEmpty
                                                              ? Colors.grey[600]
                                                              : Colors
                                                                    .grey[400],
                                                          fontStyle:
                                                              permission
                                                                  .reason
                                                                  .isNotEmpty
                                                              ? FontStyle.normal
                                                              : FontStyle
                                                                    .italic,
                                                          height: 1.4,
                                                        ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  timeago(permission.modified),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.greyColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                    ),
                  ],
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.document_text,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No permission requests found',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull to refresh or adjust filters',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
