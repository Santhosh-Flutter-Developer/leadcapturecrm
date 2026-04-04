// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/firebase/src/workpermission_service.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Project imports:
import '/constants/constants.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

class DashboardWorktimeDetail extends StatefulWidget {
  final String userId;
  const DashboardWorktimeDetail({super.key, required this.userId});

  @override
  State<DashboardWorktimeDetail> createState() =>
      _DashboardWorktimeDetailState();
}

class _DashboardWorktimeDetailState extends State<DashboardWorktimeDetail> {
  late Future _handler;
  List<WorktimeModel> _wList = [];
  List<WorkPermissionModel> _pList = [];
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    _handler = _init();
    super.initState();
  }

  _init() async {
    _wList.clear();
    _pList.clear();
    _wList = await WorktimeService.userWorktimeListing(userId: widget.userId);

    _pList = await WorkPermissionService.userPermissionListing(
      userId: widget.userId,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Back(),
        title: const Text("Worktime Detail"),
      ),
      body: FutureBuilder(
        future: _handler,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return SfCalendar(
              selectionDecoration: const BoxDecoration(),
              showCurrentTimeIndicator: false,
              headerHeight: 30,
              headerStyle: CalendarHeaderStyle(
                backgroundColor: AppColors.white,
                textAlign: TextAlign.center,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              minDate: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                00,
                00,
                00,
              ),
              maxDate: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                23,
                59,
                59,
              ),
              headerDateFormat: 'dd-MM-yyyy',
              backgroundColor: AppColors.white,
              view: CalendarView.day,
              dataSource: WorktimeCalendarDataSource(_wList, _pList),
              initialSelectedDate: _selectedDate,
              timeSlotViewSettings: const TimeSlotViewSettings(
                timeInterval: Duration(minutes: 30),
                timeFormat: 'h:mm a',
                minimumAppointmentDuration: Duration(minutes: 15),
              ),
              allowViewNavigation: true,
            );
          }
        },
      ),
    );
  }
}

class WorktimeCalendarDataSource extends CalendarDataSource {
  WorktimeCalendarDataSource(
    List<WorktimeModel> worktimes,
    List<WorkPermissionModel> permissions,
  ) {
    List<Appointment> appointments = [];

    for (var work in worktimes) {
      DateTime workStart = work.clockIn;
      DateTime? workEnd = work.clockOut ?? DateTime.now();

      if (work.breaks.isNotEmpty) {
        // Sort breaks by start time
        var sortedBreaks = work.breaks.entries.toList()
          ..sort(
            (a, b) =>
                a.value["start"].toDate().compareTo(b.value["start"].toDate()),
          );

        for (var i = 0; i < sortedBreaks.length; i++) {
          var breakStart = sortedBreaks[i].value["start"].toDate();
          var breakEnd =
              sortedBreaks[i].value["end"]?.toDate() ?? DateTime.now();

          appointments.add(
            Appointment(
              startTime: workStart,
              endTime: breakStart,
              subject:
                  "Worktime\n${workStart.formatTime} To ${DateFormat('hh:mm a').format(breakStart)}",
              color: Colors.blue,
            ),
          );

          appointments.add(
            Appointment(
              startTime: breakStart,
              endTime: breakEnd,
              subject:
                  "Break\n${DateFormat('hh:mm a').format(breakStart)} To ${DateFormat('hh:mm a').format(breakEnd)}",
              color: Colors.teal,
            ),
          );

          workStart = breakEnd;
        }
      }

      if (workStart.isBefore(workEnd)) {
        appointments.add(
          Appointment(
            startTime: workStart,
            endTime: workEnd,
            subject:
                "Worktime\n${workStart.formatTime} To ${workEnd.formatTime}",
            color: Colors.blue,
          ),
        );
      }
    }

    for (var perm in permissions) {
      appointments.add(
        Appointment(
          startTime: perm.from,
          endTime: perm.to,
          subject:
              "Permission: ${perm.reason}\n${perm.from.formatTime} To ${perm.to.formatTime} (Status: ${perm.status.name.capitalizeFirst})",
          color: perm.status == PermissionsStatus.approved
              ? Colors.green
              : perm.status == PermissionsStatus.rejected
              ? Colors.red
              : Colors.orange,
        ),
      );
    }

    this.appointments = appointments;
  }
}
