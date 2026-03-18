/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/utils/src/time_format.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

// Project imports:
import '/theme/theme.dart';
import '/utils/utils.dart';

class WorktimeReportView extends StatefulWidget {
  final String id;
  const WorktimeReportView({super.key, required this.id});

  @override
  State<WorktimeReportView> createState() => _WorktimeReportViewState();
}

class _WorktimeReportViewState extends State<WorktimeReportView> {
  late Future _worktimeReportFuture;
  WorktimeModel? _model;
  Duration totalBreaks = Duration.zero;
  Duration totalWorktime = Duration.zero;

  @override
  void initState() {
    _worktimeReportFuture = _init();
    super.initState();
  }

  _init() async {
    _model = await WorktimeService.getClockIn(id: widget.id);

    if (_model != null) {
      // Calculate total breaks
      for (var breakEntry in _model!.breaks.entries) {
        var start = breakEntry.value["start"].toDate();
        var end = breakEntry.value["end"].toDate();
        totalBreaks += end.difference(start);
      }

      // Calculate total worktime
      var clockIn = _model!.clockIn;
      var clockOut = _model!.clockOut;
      if (clockOut != null) {
        totalWorktime = clockOut.difference(clockIn) - totalBreaks;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const Back(), title: const Text("Worktime View")),
      body: FutureBuilder(
        future: _worktimeReportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return ListView(
              padding: const EdgeInsets.all(10),
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                "Total Worktime",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                formatDuration(totalWorktime),
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                "Total Breaks",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                formatDuration(totalBreaks),
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Text.rich(
                        TextSpan(
                          text: "Clock In : ",
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text: _model?.clockIn.formatDateTime,
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: "Clock Out : ",
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text: _model?.clockOut != null
                                  ? _model?.clockOut!.formatDateTime
                                  : "--:--:--",
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Text(
                        "Breaks",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      for (var i = 0; i < _model!.breaks.entries.length; i++)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  "${i + 1}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                Text(
                                  "Start : ${_model!.breaks.entries.elementAt(i).value["start"].toDate()}",
                                ),
                                Text(
                                  "End : ${_model!.breaks.entries.elementAt(i).value["end"].toDate()}",
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
