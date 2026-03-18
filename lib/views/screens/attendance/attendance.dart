import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/user_data_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/screens/permission/src/permisson_create.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:table_calendar/table_calendar.dart';

String getAttendanceStatus(PunchModel punch) {
  if (punch.permissionType != null) {
    if (punch.permissionStatus == PermissionsStatus.approved) {
      switch (punch.permissionType!) {
        case PermissionType.leaveFullDay:
          return "Leave";
        case PermissionType.leaveHalfDay:
          return "HalfDay";
        case PermissionType.workFromHome:
          return "WFH";
        case PermissionType.lateEntry:
          return "Late";
        case PermissionType.earlyExit:
          return "EarlyExit";
        case PermissionType.permission:
          return "Permission";
      }
    } else if (punch.permissionStatus == PermissionsStatus.pending) {
      return "Pending Permission";
    } else if (punch.permissionStatus == PermissionsStatus.rejected) {
      return "Permission Rejected";
    }
  }

  if (punch.punchTime.isNotEmpty) {
    return punch.punchTime.length >= 2 ? "Present" : "Half Day";
  }

  return "Absent";
}

const String _pageTitle = "Attendance";

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  late Future _aHandler;
  UserDataModel? user;
  // bool _searchApplied = false;
  // final TextEditingController _search = TextEditingController();
  String _selectedStatus = "All";
  String _selectedType = "All";
  DateTimeRange? _selectedDateRange;
  String _dateRangeText = "Select Date Range";

  List<AttendanceModel> _aList = [];
  final List<AttendanceModel> _tempAList = [];
  AttendanceStats? _stats;
  bool isAdmin = false;
  bool isEmployee = false;

  Color _statusColor(String status) {
    switch (status) {
      case "Present":
        return Colors.green;

      case "Absent":
        return Colors.red;

      case "Leave":
        return Colors.orange;

      case "WFH":
        return Colors.blue;

      case "HalfDay":
        return Colors.amber;

      case "Late":
        return Colors.purple;

      case "EarlyExit":
        return Colors.deepOrange;

      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    _aHandler = _init();
    super.initState();
  }

  Future<void> _init() async {
    user = await Spdb.getUser();
    isAdmin = await Spdb.isAdminLoggedIn();
    isEmployee = await Spdb.isEmployeeLoggedIn();
    DateTime now = DateTime.now();
    DateTime fromDate = DateTime(now.year, now.month, 1);
    DateTime toDate = DateTime(now.year, now.month + 1, 0);

    _stats = await AttendanceService.getAttendanceStats(
      userUid: user!.userType == UserType.employee ? user!.uid : "",
      fromDate: fromDate,
      toDate: toDate,
    );

    _aList.clear();
    _tempAList.clear();

    _aList = _stats!.attendanceData;

    _aList.sort((a, b) {
      if (a.punchList.isEmpty || b.punchList.isEmpty) return 0;

      return DateTime.parse(
        b.punchList.first.punchDate,
      ).compareTo(DateTime.parse(a.punchList.first.punchDate));
    });

    _tempAList.addAll(_aList);
  }

  // void _searchAttendance() {
  //   final query = _search.text.toLowerCase();

  //   final filtered = _tempAList.where((a) {
  //     if (a.punchList.isEmpty) return false;

  //     final punch = a.punchList.first;

  //     final date = DateFormat(
  //       'yyyy-MM-dd',
  //     ).format(DateTime.parse(punch.punchDate)).toLowerCase();

  //     final status = getAttendanceStatus(punch).toLowerCase();

  //     return date.contains(query) || status.contains(query);
  //   }).toList();
  //   setState(() => _aList = filtered);
  // }

  void _showAttendanceDetails(AttendanceModel a) {
    final punch = a.punchList.first;
    final status = getAttendanceStatus(punch);

    if (punch.permissionStatus == PermissionsStatus.pending) {
      Text(
        "Permission Status : ${punch.permissionStatus?.name ?? '-'}",
        style: TextStyle(
          color: punch.permissionStatus == PermissionsStatus.approved
              ? Colors.green
              : punch.permissionStatus == PermissionsStatus.rejected
              ? Colors.red
              : Colors.orange,
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String checkIn = punch.punchTime.isNotEmpty
            ? punch.punchTime.first
            : "-";

        String checkOut = punch.punchTime.length > 1
            ? punch.punchTime.last
            : "-";

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                DateFormat(
                  'EEEE, MMM dd yyyy',
                ).format(DateTime.parse(punch.punchDate)),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Checkin Checkout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile(Iconsax.login, "Check In", checkIn),
                  _infoTile(Iconsax.logout, "Check Out", checkOut),
                ],
              ),

              const SizedBox(height: 15),

              /// Work Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile(Iconsax.clock, "Work", a.workingHourMinutes),
                  _infoTile(Iconsax.flash, "OT", a.otHourMinutes),
                  _infoTile(Iconsax.warning_2, "Less", a.lessHourMinutes),
                ],
              ),

              const SizedBox(height: 15),

              /// Permission info
              if (punch.permissionType != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.warning_2, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(
                        "Permission : ${punch.permissionType!.name}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              if (punch.permissionStatus != null)
                Text(
                  "Status : ${punch.permissionStatus!.name}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: punch.permissionStatus == PermissionsStatus.approved
                        ? Colors.green
                        : punch.permissionStatus == PermissionsStatus.rejected
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    List<AttendanceModel> filtered = _tempAList.where((a) {
      if (a.punchList.isEmpty) return false;

      final punch = a.punchList.first;
      final status = getAttendanceStatus(punch);
      final type = punch.permissionType?.name ?? "";

      bool matchesStatus = _selectedStatus == "All"
          ? true
          : status == _selectedStatus;
      bool matchesType = _selectedType == "All" ? true : type == _selectedType;
      bool matchesDate = true;

      if (_selectedDateRange != null) {
        final punchDate = DateTime.parse(punch.punchDate);
        matchesDate =
            punchDate.isAfter(
              _selectedDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            punchDate.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            );
      }

      return matchesStatus && matchesType && matchesDate;
    }).toList();

    setState(() {
      _aList = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _aList.any(
      (a) =>
          a.punchList.isNotEmpty &&
          a.punchList.first.permissionStatus == PermissionsStatus.pending,
    );

    return Scaffold(
      floatingActionButton: isEmployee && !hasPending
          ? FloatingActionButton(
              tooltip: "Request Permission",
              child: const Icon(Iconsax.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PermissonCreate()),
                );
              },
            )
          : null,
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          _aHandler = _init();
          setState(() {});
        },
        child: FutureBuilder<void>(
          future: _aHandler,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            }
            // if (_aList.isEmpty) {
            //   return const NoData();
            // }
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Row(
                    //   children: [
                    //     IconButton(
                    //       icon: const Icon(Iconsax.arrow_left),
                    //       onPressed: prevMonth,
                    //     ),
                    //     Expanded(
                    //       child: Text(
                    //         DateFormat('MMM yyyy').format(focusedMonth),
                    //         textAlign: TextAlign.center,
                    //         style: const TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //     ),
                    //     IconButton(
                    //       icon: const Icon(Iconsax.arrow_right),
                    //       onPressed: nextMonth,
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 12),
                    if (isAdmin) ...[
                      _permissionApprovalPanel(),
                      const SizedBox(height: 16),
                      _filterPanel(),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildSummaryCards(_stats!),
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin) _attendanceListView(),
                    const SizedBox(height: 20),
                    _AttendanceCalendar(
                      attendanceList: _aList,
                      onDayTap: (date) {
                        final aListForDay = _aList
                            .where(
                              (e) =>
                                  e.punchList.isNotEmpty &&
                                  e.punchList.first.punchDate.startsWith(
                                    DateFormat('yyyy-MM-dd').format(date),
                                  ),
                            )
                            .toList();

                        if (aListForDay.isNotEmpty) {
                          _showAttendanceDetails(aListForDay.first);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No attendance record for this day',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String minutes) {
    final m = int.tryParse(minutes) ?? 0;
    final h = m ~/ 60;
    final r = m % 60;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.blue),
        ),

        const SizedBox(height: 6),

        Text(
          "${h}h ${r}m",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _permissionApprovalPanel() {
    final pendingPermissions = _aList
        .where(
          (a) =>
              a.punchList.isNotEmpty &&
              a.punchList.first.permissionStatus == PermissionsStatus.pending,
        )
        .toList();

    if (pendingPermissions.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Iconsax.warning_2, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Pending Permission Requests",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...pendingPermissions.map((a) {
              final punch = a.punchList.first;

              return Card(
                elevation: 0,
                color: Colors.orange.withOpacity(.07),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    punch.permissionType!.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.parse(punch.punchDate)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          await AttendanceService.updatePermissionStatus(
                            punchId: punch.uid!,
                            status: PermissionsStatus.approved,
                          );

                          _aHandler = _init();
                          setState(() {});
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await AttendanceService.updatePermissionStatus(
                            punchId: punch.uid!,
                            status: PermissionsStatus.rejected,
                          );

                          _aHandler = _init();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceStats stats) {
    final items = [
      ("Present", stats.presentDays.toString(), Colors.green),
      ("Absent", stats.absentDays.toString(), Colors.red),
      ("Leave", stats.leaveDays.toString(), Colors.orange),
      ("WFH", stats.wfhDays.toString(), Colors.blue),
    ];

    if (isAdmin) {
      items.addAll([
        ("Half Day", stats.halfDayDays.toString(), Colors.amber),
        ("Late", stats.lateDays.toString(), Colors.purple),
        ("Early Exit", stats.earlyExitDays.toString(), Colors.deepOrange),
        ("OT Hours", stats.totalOTHours, Colors.teal),
        ("Less Hours", stats.totalLessHours, Colors.brown),
      ]);
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];

          return _summaryCard(
            label: item.$1,
            value: item.$2,
            color: item.$3,
            width: screenWidth * 0.19,
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getSummaryIcon(label), color: color, size: 25),
          ),

          const SizedBox(width: 10),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSummaryIcon(String label) {
    switch (label.toLowerCase()) {
      case 'present':
        return Iconsax.user_tick;

      case 'absent':
        return Iconsax.user_minus;

      case 'leave':
        return Iconsax.calendar_remove;

      case 'wfh':
        return Iconsax.home;

      case 'half day':
        return Iconsax.clock;

      case 'late':
        return Iconsax.timer_1;

      case 'early exit':
        return Iconsax.logout;

      case 'ot hours':
        return Iconsax.flash;

      case 'less hours':
        return Iconsax.warning_2;

      default:
        return Iconsax.user;
    }
  }

  Widget _filterPanel() {
    final statusOptions = [
      "All",
      "Present",
      "Absent",
      "Leave",
      "WFH",
      "HalfDay",
      "Late",
      "EarlyExit",
      "Pending Permission",
      "Permission Rejected",
    ];

    final typeOptions = [
      "All",
      "Leave",
      "HalfDay",
      "WFH",
      "Late",
      "EarlyExit",
      "Permission",
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "Filters",
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * .2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: statusOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val!;
                        _applyFilters();
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: MediaQuery.of(context).size.width * .2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Permission",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: typeOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val!;
                        _applyFilters();
                      });
                    },
                  ),
                ),

                OutlinedButton.icon(
                  icon: const Icon(Iconsax.calendar),
                  label: Text(_dateRangeText),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                      initialDateRange: _selectedDateRange,
                    );

                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                        _dateRangeText =
                            "${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM').format(picked.end)}";
                        _applyFilters();
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceListView() {
    if (_aList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.calendar_remove,
                size: 40,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 18),

            /// TITLE
            const Text(
              "No Attendance Records",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            /// SUBTITLE
            Text(
              "Attendance data will appear here once records are available.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            // if (isAdmin)
            //   OutlinedButton.icon(
            //     icon: const Icon(Iconsax.refresh),
            //     label: const Text("Refresh"),
            //     onPressed: () {
            //       _aHandler = _init();
            //       setState(() {});
            //     },
            //   ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _aList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = _aList[index];
        final punch = a.punchList.first;
        final status = getAttendanceStatus(punch);
        final color = _statusColor(status);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAttendanceDetails(a),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  /// DATE CIRCLE
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withOpacity(.15),
                    child: Text(
                      DateFormat('dd').format(DateTime.parse(punch.punchDate)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  /// DATE + STATUS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEE, MMM dd yyyy',
                          ).format(DateTime.parse(punch.punchDate)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 4),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// PERMISSION
                  if (punch.permissionType != null)
                    Text(
                      punch.permissionType!.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttendanceCalendar extends StatefulWidget {
  final List<AttendanceModel> attendanceList;
  final void Function(DateTime) onDayTap;

  const _AttendanceCalendar({
    required this.attendanceList,
    required this.onDayTap,
  });

  @override
  State<_AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<_AttendanceCalendar> {
  DateTime focusedMonth = DateTime.now();

  void prevMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
    });
  }

  void nextMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<DateTime, String> attendanceMap = {};

    for (var a in widget.attendanceList) {
      if (a.punchList.isEmpty) continue;

      var punch = a.punchList.first;

      DateTime? date = DateTime.tryParse(punch.punchDate);
      if (date == null) continue;

      String status = getAttendanceStatus(punch);

      attendanceMap[DateTime(date.year, date.month, date.day)] = status;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                nextMonth();
              } else {
                prevMonth();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Calendar View",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime(2025, 1, 1),
                  lastDay: DateTime(2027, 12, 31),
                  focusedDay: focusedMonth,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.withOpacity(.3),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final status =
                          attendanceMap[DateTime(day.year, day.month, day.day)];

                      Color? markerColor;

                      switch (status) {
                        case "Present":
                          markerColor = Colors.green;
                          break;

                        case "Absent":
                          markerColor = Colors.red;
                          break;

                        case "Leave":
                          markerColor = Colors.orange;
                          break;

                        case "HalfDay":
                          markerColor = Colors.amber;
                          break;

                        case "WFH":
                          markerColor = Colors.blue;
                          break;

                        case "Late":
                          markerColor = Colors.purple;
                          break;

                        case "EarlyExit":
                          markerColor = Colors.deepOrange;
                          break;

                        case "Pending Permission":
                          markerColor = Colors.grey;
                          break;
                      }

                      bool isToday =
                          day.year == DateTime.now().year &&
                          day.month == DateTime.now().month &&
                          day.day == DateTime.now().day;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  markerColor?.withOpacity(0.3) ??
                                  Colors.transparent,
                              shape: BoxShape.circle,
                              border: isToday
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Center(child: Text("${day.day}")),
                          ),

                          if (isToday)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() => focusedMonth = focusedDay);
                    widget.onDayTap(selectedDay);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
