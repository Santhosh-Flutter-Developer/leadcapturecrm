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
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/utils/src/time_format.dart';
import 'package:leadcapture/views/components/src/sheet.dart';
import 'package:leadcapture/views/screens/worktime/src/worktime_create.dart';
import 'package:leadcapture/views/screens/worktime/src/worktime_report/src/worktime_report_view.dart';
import 'package:leadcapture/views/ui/src/appbar.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/count_display.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/filter.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

// Project imports:
import '/theme/theme.dart';
import '/utils/utils.dart';

class WorktimeListing extends StatefulWidget {
  const WorktimeListing({super.key});

  @override
  State<WorktimeListing> createState() => _WorktimeListingState();
}

class _WorktimeListingState extends State<WorktimeListing> {
  late Future _worktimeHanlder;
  FilterModel _filter = FilterModel(pageLimit: 10, pageNumber: 1);
  int _worktimeCount = 0;
  List<WorktimeModel> _wList = [];
  final List<WorktimeModel> _tempPList = [];

  @override
  void initState() {
    _worktimeHanlder = _init();
    super.initState();
  }

  _init() async {
    _wList.clear();
    _tempPList.clear();
    _worktimeCount = await WorktimeService.workTimesCount();
    _wList = await WorktimeService.worktimeListing(filter: _filter);
    _wList.sort((a, b) => b.created.compareTo(a.created));
    _tempPList.addAll(_wList);
  }

  bool _searchApplied = false;
  _searchWorktime() {
    List<WorktimeModel> filteredList = _tempPList.where((payments) {
      return payments.userName.toString().toLowerCase().contains(
        _search.text.toLowerCase(),
      );
    }).toList();

    setState(() {
      _wList = filteredList;
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
            widget: Filter(filter: _filter, totalCount: _worktimeCount),
          );
          if (v != null) {
            _filter = v;
            _worktimeHanlder = _init();
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
        onChanged: (value) => _searchWorktime(),
        leading: const Back(),
        nonSearchTitle: const Text("Worktimes"),
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
          IconButton(
            tooltip: "Add",
            icon: const Icon(Iconsax.add, size: 28, weight: 30),
            onPressed: () async {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    return const WorktimeCreate();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _worktimeHanlder = _init();
          setState(() {});
        },
        child: FutureBuilder(
          future: _worktimeHanlder,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              if (_wList.isNotEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    CountDisplay(
                      pageLimit: _filter.pageLimit,
                      pageNumber: _filter.pageNumber,
                      totalCount: _worktimeCount,
                    ),
                    ListView.separated(
                      primary: false,
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: _wList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            var v = await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) {
                                  return WorktimeReportView(
                                    id: _wList[index].uid ?? '',
                                  );
                                },
                              ),
                            );
                            if (v != null) {
                              if (v) {
                                _worktimeHanlder = _init();
                                setState(() {});
                              }
                            }
                          },
                          onLongPress: () async {
                            // var v = await showDialog(
                            //   barrierDismissible: false,
                            //   context: context,
                            //   builder: (context) => DeleteDialog(
                            //     text: " ${_wList[index].clockIn}",
                            //   ),
                            // );
                            // if (v != null) {
                            //   if (v) {
                            //     try {
                            //       futureLoading(context);
                            //       await PaymentMethodFunctions
                            //           .deletePaymentMethod(
                            //               uid: _wList[index].uid ?? '');
                            //       Navigator.pop(context);
                            //       Snackbar.showSnackBar(context,
                            //           content: "Payment method deleted",
                            //           isSuccess: true);
                            //       _worktimeHanlder = _init();
                            //       setState(() {});
                            //     } catch (e) {
                            //       Navigator.pop(context);
                            //       Snackbar.showSnackBar(context,
                            //           content: e.toString(), isSuccess: false);
                            //     }
                            //   }
                            // }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhiteColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _wList[index].clockIn.formatDate,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "In : ${_wList[index].clockIn.formatDateTime}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Out : ${_wList[index].clockOut != null ? _wList[index].clockOut!.formatDateTime : ""}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Modified: ${timeago(_wList[index].modified)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: AppColors.greyColor,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: "Created Date",
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat(
                                          "MMM",
                                        ).format(_wList[index].created),
                                      ),
                                      Text(
                                        DateFormat(
                                          "dd",
                                        ).format(_wList[index].created),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(color: Colors.grey.shade300);
                      },
                    ),
                  ],
                );
              } else {
                return const NoData();
              }
            }
          },
        ),
      ),
    );
  }
}
