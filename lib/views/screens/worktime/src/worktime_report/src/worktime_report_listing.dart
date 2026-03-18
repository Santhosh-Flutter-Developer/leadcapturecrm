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
import 'package:leadcapture/utils/src/xls_export.dart';
import 'package:leadcapture/views/components/src/sheet.dart' show Sheet;
import 'package:leadcapture/views/screens/worktime/src/worktime_report/src/worktime_report_view.dart';
import 'package:leadcapture/views/ui/src/appbar.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/count_display.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:leadcapture/views/ui/src/snackbar.dart';

// Project imports:
import '../../../../../ui/src/filter.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

class WorktimeReportListing extends StatefulWidget {
  const WorktimeReportListing({super.key});

  @override
  State<WorktimeReportListing> createState() => _WorktimeReportListingState();
}

class _WorktimeReportListingState extends State<WorktimeReportListing> {
  late Future _paymentListingHanlder;
  FilterModel _filter = FilterModel(pageLimit: 10, pageNumber: 1);
  int _worktimeCount = 0;
  List<WorktimeModel> _pList = [];
  final List<WorktimeModel> _tempPList = [];

  @override
  void initState() {
    _paymentListingHanlder = _init();
    super.initState();
  }

  _init() async {
    _pList.clear();
    _tempPList.clear();
    _worktimeCount = await WorktimeService.workTimesReportCount();
    _pList = await WorktimeService.worktimeListingReport(filter: _filter);
    _pList.sort((a, b) => b.created.compareTo(a.created));
    _tempPList.addAll(_pList);
  }

  bool _searchApplied = false;
  _searchPaymentMethod() {
    List<WorktimeModel> filteredList = _tempPList.where((payments) {
      return payments.clockIn.toString().toLowerCase().contains(
        _search.text.toLowerCase(),
      );
    }).toList();

    setState(() {
      _pList = filteredList;
    });
  }

  final TextEditingController _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        foregroundColor: AppColors.white,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () async {
          var v = await Sheet.showSheet(
            context,
            size: 0.9,
            widget: Filter(filter: _filter, totalCount: _worktimeCount),
          );
          if (v != null) {
            _filter = v;
            _paymentListingHanlder = _init();
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
        onChanged: (value) => _searchPaymentMethod(),
        leading: const Back(),
        nonSearchTitle: const Text("Worktime Report"),
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
            icon: const Icon(CupertinoIcons.arrow_down_doc_fill),
            onPressed: () {
              if (_pList.isNotEmpty) {
                XlsExport.workTimeReportExport(model: _pList);
              } else {
                Snackbar.showSnackBar(
                  context,
                  content: "No data found to export",
                  isSuccess: false,
                );
              }
            },
          ),
          // IconButton(
          //   tooltip: "Add",
          //   icon: const Icon(Iconsax.add, size: 28, weight: 30),
          //   onPressed: () async {
          //   },
          // )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _paymentListingHanlder = _init();
          setState(() {});
        },
        child: FutureBuilder(
          future: _paymentListingHanlder,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              if (_pList.isNotEmpty) {
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
                      itemCount: _pList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            var v = await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) {
                                  return WorktimeReportView(
                                    id: _pList[index].uid ?? '',
                                  );
                                },
                              ),
                            );
                            if (v != null) {
                              if (v) {
                                _paymentListingHanlder = _init();
                                setState(() {});
                              }
                            }
                          },
                          onLongPress: () async {
                            // var v = await showDialog(
                            //   barrierDismissible: false,
                            //   context: context,
                            //   builder: (context) => DeleteDialog(
                            //     text: " ${_pList[index].clockIn}",
                            //   ),
                            // );
                            // if (v != null) {
                            //   if (v) {
                            //     try {
                            //       futureLoading(context);
                            //       await PaymentMethodFunctions
                            //           .deletePaymentMethod(
                            //               uid: _pList[index].uid ?? '');
                            //       Navigator.pop(context);
                            //       Snackbar.showSnackBar(context,
                            //           content: "Payment method deleted",
                            //           isSuccess: true);
                            //       _paymentListingHanlder = _init();
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
                              color: AppColors.white,
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
                                        _pList[index].userName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _pList[index].clockIn.formatDateTime,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Modified: ${timeago(_pList[index].modified)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(color: AppColors.grey),
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
                                        ).format(_pList[index].created),
                                      ),
                                      Text(
                                        DateFormat(
                                          "dd",
                                        ).format(_pList[index].created),
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
