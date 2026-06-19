/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/constants/src/svg.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/database/src/db.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/utils/src/time_format.dart';
import 'package:leadcapture/views/components/src/sheet.dart';
import 'package:leadcapture/views/screens/worktime/src/clockout_dialog.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/button.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:leadcapture/views/ui/src/snackbar.dart';

// Project imports:
import '/services/services.dart';
import '/theme/theme.dart';

class WorktimeCreate extends StatefulWidget {
  const WorktimeCreate({super.key});

  @override
  State<WorktimeCreate> createState() => _WorktimeCreateState();
}

const String _pageTitle = "Work Time";

class _WorktimeCreateState extends State<WorktimeCreate> {
  bool _alreadyClockIned = false;
  bool _isInBreak = false;
  bool _dayEnd = false;
  bool _previousDayNotFinished = false;

  WorktimeModel? _worktimeModel;

  Timer? _worktimeTimer;
  Timer? _breaktimeTimer;
  Duration _elapsedWorkTime = Duration.zero;
  Duration _elapsedBreakTime = Duration.zero;
  late Future<void> _workTimeHandler;

  @override
  void initState() {
    _workTimeHandler = _init();
    super.initState();
  }

  Future<void> _init() async {
    _dayEnd = await WorktimeService.checkDayEnd();

    // ✅ If day ended → reset everything
    if (_dayEnd) {
      await Db.clearClockIn();
      _alreadyClockIned = false;
      _isInBreak = false;
      _worktimeModel = null;
      setState(() {});
      return;
    }

    // ✅ Get active clock-in from Firestore
    String? workTimeId = await WorktimeService.checkAlreadyClockedInReturnId();

    if (workTimeId != null) {
      _alreadyClockIned = true;

      // Save locally
      await Db.setClockIn(workTimeId);

      // Fetch data
      var clockIn = await WorktimeService.getClockIn(id: workTimeId);

      // Check previous day
      if (clockIn.created.year != DateTime.now().year ||
          clockIn.created.month != DateTime.now().month ||
          clockIn.created.day != DateTime.now().day) {
        _previousDayNotFinished = true;
      }

      _worktimeModel = clockIn;
    } else {
      _alreadyClockIned = false;
    }

    // ✅ Restore timers
    if (_worktimeModel != null) {
      final clockInTime = _worktimeModel!.clockIn;

      Duration totalBreak = Duration.zero;
      bool isInBreak = false;

      _worktimeModel!.breaks.forEach((key, value) {
        final breakStart = value["start"].toDate();
        final breakEnd = value["end"]?.toDate();

        if (breakEnd == null) {
          isInBreak = true;
          _elapsedBreakTime = DateTime.now().difference(breakStart);
          totalBreak += _elapsedBreakTime;
        } else {
          totalBreak += breakEnd.difference(breakStart);
        }
      });

      _elapsedWorkTime = DateTime.now().difference(clockInTime) - totalBreak;

      if (isInBreak) {
        _isInBreak = true;
        _breakTimer();
      } else {
        _isInBreak = false;
        _startTimer();
      }
    }

    setState(() {});
  }

  void _startTimer() {
    _worktimeTimer?.cancel();
    _worktimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedWorkTime += const Duration(seconds: 1);
      });
    });
  }

  void _breakTimer() {
    _breaktimeTimer?.cancel();
    _breaktimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedBreakTime += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _worktimeTimer?.cancel();
    _breaktimeTimer?.cancel();
    super.dispose();
  }

  void _clockIn() async {
    try {
      futureLoading(context);

      var uid = await Spdb.getUid();
      var user = await Spdb.getUser();
      var name = user.name;

      var existing = await WorktimeService.checkTodayClockIn();
      if (existing) {
        Navigator.pop(context);
        Snackbar.showSnackBar(
          context,
          content: "You already clocked in today",
          isSuccess: false,
        );
        return;
      }

      var id = await WorktimeService.createWorkTime(
        model: WorktimeModel(
          breaks: {},
          clockIn: DateTime.now(),
          userUid: uid ?? '',
          userName: name,
          created: DateTime.now(),
          modified: DateTime.now(),
        ),
      );
      Db.setClockIn(id);
      _worktimeModel = await WorktimeService.getClockIn(id: id);
      _alreadyClockIned = true;
      _elapsedWorkTime = Duration.zero;
      _startTimer();

      Navigator.pop(context);
      setState(() {});
    } catch (e, stackTrace) {
      Navigator.pop(context);
      debugPrint("❌ ClockIn Error: $e");
      debugPrint("📍 StackTrace: $stackTrace");
      Snackbar.showSnackBar(context, content: e.toString(), isSuccess: false);
    }
  }

  void _break() async {
    try {
      if (_worktimeModel == null) {
        Snackbar.showSnackBar(
          context,
          content: "Clock in first",
          isSuccess: false,
        );
        return;
      }
      futureLoading(context);
      if (!_isInBreak) {
        final breakId = (_worktimeModel!.breaks.length + 1).toString();
        _worktimeModel!.breaks[breakId] = {
          "start": DateTime.now(),
          "end": null,
        };

        var workTimeId = await Db.getClockIn();

        await WorktimeService.updateWorkTime(
          id: workTimeId ?? '',
          model: _worktimeModel!,
        );

        _worktimeModel = await WorktimeService.getClockIn(id: workTimeId ?? '');

        // Update state and start the break timer
        setState(() {
          _isInBreak = true;
          _elapsedBreakTime = Duration.zero;
        });

        // Stop the work timer and start the break timer
        _worktimeTimer?.cancel();
        _breakTimer();
      } else {
        // End the current break
        final currentBreak = _worktimeModel!.breaks.entries.firstWhere(
          (entry) => entry.value["end"] == null,
        );

        currentBreak.value["end"] = DateTime.now();

        var workTimeId = await Db.getClockIn();

        await WorktimeService.updateWorkTime(
          id: workTimeId ?? '',
          model: _worktimeModel!,
        );

        // Cancel the break timer and reset the break state
        _breaktimeTimer?.cancel();

        _worktimeModel = await WorktimeService.getClockIn(id: workTimeId ?? '');

        setState(() {
          _isInBreak = false;
          _elapsedBreakTime = Duration.zero;
        });

        // Restart the work timer
        _startTimer();
      }
      Navigator.pop(context);
    } catch (e) {
      Snackbar.showSnackBar(context, content: e.toString(), isSuccess: false);
    }
  }

  Duration _calculateTotalBreakTime() {
    Duration totalBreakDuration = Duration.zero;

    for (var entry in _worktimeModel!.breaks.entries) {
      final start = entry.value["start"] as DateTime;
      final end = entry.value["end"] as DateTime?;

      if (end != null) {
        totalBreakDuration += end.difference(start);
      }
    }

    return totalBreakDuration;
  }

  void _clockOut() async {
    try {
      futureLoading(context);

      var workTimeId = await Db.getClockIn();

      if (_isInBreak) {
        final currentBreak = _worktimeModel!.breaks.entries.firstWhere(
          (entry) => entry.value["end"] == null,
        );

        currentBreak.value["end"] = DateTime.now();

        await WorktimeService.updateWorkTime(
          id: workTimeId ?? '',
          model: _worktimeModel!,
        );

        _breaktimeTimer?.cancel();
        _elapsedBreakTime = Duration.zero;
        _isInBreak = false;
      }

      // ✅ Clockout
      await WorktimeService.clockOut(id: workTimeId ?? '');

      await Db.clearClockIn();

      _worktimeTimer?.cancel();
      _breaktimeTimer?.cancel();

      _alreadyClockIned = false;
      _worktimeModel = null;

      _elapsedWorkTime = Duration.zero;
      _elapsedBreakTime = Duration.zero;

      _isInBreak = false;
      _dayEnd = true;

      Navigator.pop(context);

      setState(() {});
    } catch (e, stackTrace) {
      Navigator.pop(context);

      debugPrint("❌ ClockOut Error: $e");
      debugPrint("📍 StackTrace: $stackTrace");
      Snackbar.showSnackBar(context, content: e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: FutureBuilder(
        future: _workTimeHandler,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.string(clock, height: 200, width: 200),
                  if (_previousDayNotFinished)
                    Column(
                      children: [
                        Text(
                          "You are not clockout previous day",
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        Button(
                          event: () async {
                            var result = await Sheet.showSheet(
                              context,
                              size: 0.6,
                              widget: ClockoutDialog(model: _worktimeModel!),
                            );
                            if (result != null) {
                              futureLoading(context);
                              await WorktimeService.updatePreviousDayClockOut(
                                id: _worktimeModel?.uid ?? '',
                                model: result,
                              );
                              await Db.clearClockIn();
                              Navigator.pop(context);
                              _workTimeHandler = _init();
                            }
                          },
                          text: "Clock out",
                          icon: Iconsax.clock,
                        ),
                      ],
                    ),
                  if (_dayEnd && !_previousDayNotFinished)
                    Text(
                      "Day Ended",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  if (!_dayEnd && !_previousDayNotFinished)
                    if (_alreadyClockIned)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Worktime : ${formatDuration(_elapsedWorkTime)}",
                            style: Theme.of(context).textTheme.titleLarge!
                                .copyWith(
                                  color: _isInBreak
                                      ? AppColors.grey
                                      : AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          if (_isInBreak)
                            Text(
                              "Break : ${_isInBreak ? formatDuration(_elapsedBreakTime) : formatDuration(_calculateTotalBreakTime())}",
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(
                                    color: _isInBreak
                                        ? AppColors.primary
                                        : AppColors.grey,
                                  ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Button(
                                event: () {
                                  _break();
                                },
                                text: _isInBreak ? "End Break" : "Break",
                              ),
                              const SizedBox(width: 5),
                              Button(
                                event: () {
                                  _clockOut();
                                },
                                text: "Clock Out",
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Button(
                            event: () {
                              _clockIn();
                            },
                            text: "Clock in",
                            icon: Iconsax.clock,
                          ),
                        ],
                      ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
