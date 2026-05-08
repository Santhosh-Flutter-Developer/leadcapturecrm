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

const String _pageTitle = "Permission Requests";

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

  // final bool _searchApplied = false;
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
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
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
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _search,
                        onChanged: (value) => _searchPermission(),
                        decoration: InputDecoration(
                          hintText: "Search by name...",
                          prefixIcon: Icon(
                            Icons.search,
                            color: _search.text.isEmpty
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_search.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    _rList = _tempRList;
                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CountDisplay(
                        pageLimit: _filter.pageLimit,
                        pageNumber: _filter.pageNumber,
                        totalCount: _pCount,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
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
                                  ).withValues(alpha: 0.2),
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
                                      10,
                                      8,
                                      10,
                                      10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
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
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: getStatusColor(
                                                  permission.status.name,
                                                ).withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: getStatusColor(
                                                    permission.status.name,
                                                  ).withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                permission
                                                    .status
                                                    .name
                                                    .capitalizeFirst,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: getStatusColor(
                                                        permission.status.name,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        RichText(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _permissionTypeText(
                                                  permission,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors
                                                          .primaryColor,
                                                    ),
                                              ),
                                              const TextSpan(
                                                text: "  •  ",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
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
                                                          ? Colors.grey[700]
                                                          : Colors.grey[400],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                                    _formatDuration(duration),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors.green[700],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const Spacer(),

                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                /// 📅 DATE BADGE
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.blue
                                                          .withValues(alpha: 0.2),
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

                                                const SizedBox(height: 4),

                                                Text(
                                                  timeago(permission.modified),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontSize: 10,
                                                        color:
                                                            AppColors.greyColor,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),
                                        Divider(
                                          color: Colors.grey[200],
                                          height: 1,
                                        ),
                                        const SizedBox(height: 6),

                                        if (permission.withSalary ||
                                            permission.approvedBy != null ||
                                            permission.approvedAt != null)
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (permission.withSalary)
                                                _smallChip(
                                                  "With Salary",
                                                  Colors.blue,
                                                ),

                                              if (permission.approvedBy != null)
                                                _iconText(
                                                  Icons.person_outline,
                                                  permission.approvedBy!,
                                                ),

                                              if (permission.approvedAt != null)
                                                _iconText(
                                                  Icons.event,
                                                  DateFormat('MMM dd').format(
                                                    permission.approvedAt!,
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
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                      ),
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

  Widget _smallChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
