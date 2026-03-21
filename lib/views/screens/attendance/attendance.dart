import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/department_model.dart';
import 'package:leadcapture/models/src/employee_model.dart';
import 'package:leadcapture/models/src/user_data_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/screens/permission/src/permisson_create.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:table_calendar/table_calendar.dart';

String getAttendanceStatus(PunchModel punch) {
  final type = punch.permissionType;
  final status = punch.permissionStatus;

  if (status == PermissionsStatus.pending) return "Pending";
  if (status == PermissionsStatus.rejected) return "Rejected";

  if (status == PermissionsStatus.approved && type != null) {
    switch (type) {
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
  }

  final punchStatus = (punch.status).toLowerCase();

  switch (punchStatus) {
    case "present":
      return "Present";
    case "halfday":
      return "HalfDay";
    case "leave":
      return "Leave";
    case "absent":
    default:
      return "Absent";
  }
}

DateTime? _parseDate(String? date) {
  if (date == null || date.isEmpty) return null;

  final formats = ['yyyy-MM-dd', 'dd-MM-yyyy', 'dd/MM/yyyy', 'yyyy/MM/dd'];

  for (final format in formats) {
    try {
      return DateFormat(format).parse(date);
    } catch (_) {}
  }

  try {
    return DateTime.parse(date);
  } catch (_) {}

  print("❌ Invalid date format: $date");
  return null;
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
  List<AttendanceModel> filteredList = [];
  final List<AttendanceModel> _tempAList = [];
  final List<EmployeeModel> _employees = [];
  final List<DepartmentModel> _departments = [];
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
    _tempAList.addAll(_aList);

    filteredList = List.from(_aList);

    _aList.sort((a, b) {
      if (a.punchList.isEmpty || b.punchList.isEmpty) return 0;

      final dateA = _parseDate(a.punchList.first.punchDate);
      final dateB = _parseDate(b.punchList.first.punchDate);

      if (dateA == null || dateB == null) return 0;

      return dateB.compareTo(dateA);
    });
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String formatTime(String? time) {
          if (time == null || time.isEmpty) return "-";
          final dt = DateTime.tryParse(time);
          if (dt == null) return "-";
          return TimeOfDay.fromDateTime(dt).format(context);
        }

        String checkIn = punch.punchTime.isNotEmpty
            ? formatTime(punch.punchTime.first)
            : "-";

        String checkOut = punch.punchTime.length > 1
            ? formatTime(punch.punchTime.last)
            : "-";

        final date = _parseDate(punch.punchDate);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                date != null
                    ? DateFormat('EEEE, MMM dd yyyy').format(date)
                    : "--",
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile(Iconsax.login, "Check In", checkIn),
                  _infoTile(Iconsax.logout, "Check Out", checkOut),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoTile(Iconsax.clock, "Work", a.formattedWork),
                    _infoTile(Iconsax.pause, "Break", a.formattedBreak),
                    _infoTile(Iconsax.flash, "OT", a.formattedOT),
                    _infoTile(Iconsax.warning_2, "Less", a.formattedLess),
                  ],
                ),
              ),

              const SizedBox(height: 15),

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
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Permission Status : ${punch.permissionStatus!.name}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          punch.permissionStatus == PermissionsStatus.approved
                          ? Colors.green
                          : punch.permissionStatus == PermissionsStatus.rejected
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void applyFilters() {
    List<AttendanceModel> filtered = _tempAList.where((a) {
      if (a.punchList.isEmpty) return false;

      final punch = a.punchList.first;
      final status = getAttendanceStatus(punch);
      final type = punch.permissionType?.name ?? "";

      bool matchesStatus = _selectedStatus == "All"
          ? true
          : status.toLowerCase() == _selectedStatus.toLowerCase();

      bool matchesType = _selectedType == "All" ? true : type == _selectedType;

      bool matchesDate = true;

      if (_selectedDateRange != null) {
        final punchDate = _parseDate(punch.punchDate);
        if (punchDate == null) return false;

        matchesDate =
            !punchDate.isBefore(_selectedDateRange!.start) &&
            !punchDate.isAfter(_selectedDateRange!.end);
      }

      return matchesStatus && matchesType && matchesDate;
    }).toList();

    setState(() {
      filteredList = filtered;
    });
  }

  void _onDayTap(DateTime date) {
    final aListForDay = _aList.where((e) {
      if (e.punchList.isEmpty) return false;

      final parsedDate = _parseDate(e.punchList.first.punchDate);
      if (parsedDate == null) return false;

      return parsedDate.year == date.year &&
          parsedDate.month == date.month &&
          parsedDate.day == date.day;
    }).toList();

    if (aListForDay.isNotEmpty) {
      _showAttendanceDetails(aListForDay.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance record for this day')),
      );
    }
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
            return isAdmin ? _buildAdminView() : _buildEmployeeView();
            // if (_aList.isEmpty) {
            //   return const NoData();
            // }
            // return SingleChildScrollView(
            //   physics: const AlwaysScrollableScrollPhysics(),
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 16,
            //       vertical: 12,
            //     ),
            //     child: Column(
            //       children: [
            //         // Row(
            //         //   children: [
            //         //     IconButton(
            //         //       icon: const Icon(Iconsax.arrow_left),
            //         //       onPressed: prevMonth,
            //         //     ),
            //         //     Expanded(
            //         //       child: Text(
            //         //         DateFormat('MMM yyyy').format(focusedMonth),
            //         //         textAlign: TextAlign.center,
            //         //         style: const TextStyle(
            //         //           fontSize: 16,
            //         //           fontWeight: FontWeight.bold,
            //         //         ),
            //         //       ),
            //         //     ),
            //         //     IconButton(
            //         //       icon: const Icon(Iconsax.arrow_right),
            //         //       onPressed: nextMonth,
            //         //     ),
            //         //   ],
            //         // ),
            //         const SizedBox(height: 12),
            //         if (isAdmin) ...[
            //           _permissionApprovalPanel(),
            //           const SizedBox(height: 16),
            //           _filterPanel(),
            //         ],
            //         Padding(
            //           padding: const EdgeInsets.symmetric(vertical: 8),
            //           child: _buildSummaryCards(_stats!),
            //         ),
            //         const SizedBox(height: 16),
            //         _attendanceListView(),
            //         const SizedBox(height: 20),
            //         _AttendanceCalendar(
            //           attendanceList: filteredList,
            //           userType: user!.userType,
            //           employeeId: user!.uid,
            //           employees: _employees,
            //           departments: _departments,
            //           onDayTap: (date) {
            //             final aListForDay = _aList.where((e) {
            //               if (e.punchList.isEmpty) return false;

            //               final parsedDate = _parseDate(
            //                 e.punchList.first.punchDate,
            //               );
            //               if (parsedDate == null) return false;

            //               return parsedDate.year == date.year &&
            //                   parsedDate.month == date.month &&
            //                   parsedDate.day == date.day;
            //             }).toList();

            //             if (aListForDay.isNotEmpty) {
            //               _showAttendanceDetails(aListForDay.first);
            //             } else {
            //               ScaffoldMessenger.of(context).showSnackBar(
            //                 const SnackBar(
            //                   content: Text(
            //                     'No attendance record for this day',
            //                   ),
            //                 ),
            //               );
            //             }
            //           },
            //         ),
            //       ],
            //     ),
            //   ),
            // );
          },
        ),
      ),
    );
  }

  Widget _buildAdminView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔴 Pending Approvals (TOP PRIORITY)
          _permissionApprovalPanel(),
          const SizedBox(height: 16),

          /// 📊 Summary
          _buildSummaryCards(_stats!),
          const SizedBox(height: 16),

          /// 🔍 Filters
          _filterPanel(),
          const SizedBox(height: 16),

          /// 📋 Attendance List
          _attendanceListView(),
          const SizedBox(height: 20),

          /// 📅 Calendar
          _AttendanceCalendar(
            attendanceList: filteredList,
            userType: user!.userType,
            employeeId: user!.uid,
            employees: _employees,
            departments: _departments,
            onDayTap: _onDayTap,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// 📊 Personal Summary
          _buildSummaryCards(_stats!),
          const SizedBox(height: 16),

          /// 📅 Calendar (MAIN FOCUS)
          _AttendanceCalendar(
            attendanceList: filteredList,
            userType: user!.userType,
            employeeId: user!.uid,
            employees: _employees,
            departments: _departments,
            onDayTap: _onDayTap,
          ),

          const SizedBox(height: 16),

          /// 📋 My Attendance
          _attendanceListView(),
        ],
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
              final date = _parseDate(punch.punchDate);
              String formatTime(String? time) {
                if (time == null || time.isEmpty) return "-";
                final dt = DateTime.tryParse(time);
                if (dt == null) return "-";
                return TimeOfDay.fromDateTime(dt).format(context);
              }

              bool hasCheckIn = punch.punchTime.isNotEmpty;
              bool hasCheckOut = punch.punchTime.length > 1;

              final checkIn = hasCheckIn
                  ? formatTime(punch.punchTime.first)
                  : "-";
              final checkOut = hasCheckOut
                  ? formatTime(punch.punchTime.last)
                  : "-";

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

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 📅 DATE
                      Row(
                        children: [
                          const Icon(
                            Iconsax.calendar,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date != null
                                ? DateFormat('dd MMM yyyy').format(date)
                                : "--",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// ⏱ CLOCK IN / OUT
                      Row(
                        children: [
                          const Icon(
                            Iconsax.login,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(checkIn, style: const TextStyle(fontSize: 12)),

                          const SizedBox(width: 12),

                          const Icon(
                            Iconsax.logout,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(checkOut, style: const TextStyle(fontSize: 12)),
                        ],
                      ),

                      const SizedBox(height: 6),

                      if (punch.permissionStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                punch.permissionStatus ==
                                    PermissionsStatus.approved
                                ? Colors.green.withOpacity(.15)
                                : punch.permissionStatus ==
                                      PermissionsStatus.rejected
                                ? Colors.red.withOpacity(.15)
                                : Colors.orange.withOpacity(.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            punch.permissionStatus!.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  punch.permissionStatus ==
                                      PermissionsStatus.approved
                                  ? Colors.green
                                  : punch.permissionStatus ==
                                        PermissionsStatus.rejected
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                        ),
                    ],
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
      "Pending",
      "Rejected",
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
                        applyFilters();
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
                        applyFilters();
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
                        applyFilters();
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
    if (filteredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Iconsax.search_status, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              "No records found",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = filteredList[index];
        final punch = a.punchList.first;

        final status = getAttendanceStatus(punch);
        final color = _statusColor(status);
        final date = _parseDate(punch.punchDate);

        final isToday =
            date != null &&
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        /// ✅ FORMAT TIME
        String formatTime(String? time) {
          if (time == null || time.isEmpty) return "-";
          final dt = DateTime.tryParse(time);
          if (dt == null) return "-";
          return TimeOfDay.fromDateTime(dt).format(context);
        }

        final checkIn = punch.punchTime.isNotEmpty
            ? formatTime(punch.punchTime.first)
            : "-";

        final checkOut = punch.punchTime.length > 1
            ? formatTime(punch.punchTime.last)
            : "-";

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAttendanceDetails(a),
          child: Card(
            elevation: 1,
            color: isToday ? Colors.blue.withOpacity(0.05) : Colors.white,
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
                      date != null ? DateFormat('dd').format(date) : "--",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  /// MAIN CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// DATE
                        Text(
                          date != null
                              ? DateFormat('EEE, MMM dd yyyy').format(date)
                              : "--",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 4),

                        /// STATUS CHIP
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.15),
                            borderRadius: BorderRadius.circular(50),
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

                        const SizedBox(height: 6),

                        /// 🆕 CLOCK IN / OUT ROW
                        Row(
                          children: [
                            Icon(Iconsax.login, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              checkIn,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Icon(Iconsax.logout, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              checkOut,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// PERMISSION TYPE
                  if (punch.permissionType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        punch.permissionType!.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
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
  final UserType userType;
  final String? employeeId;
  final List<EmployeeModel> employees;
  final List<DepartmentModel> departments;

  const _AttendanceCalendar({
    required this.attendanceList,
    required this.onDayTap,
    required this.userType,
    this.employeeId,
    required this.employees,
    required this.departments,
  });

  @override
  State<_AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<_AttendanceCalendar> {
  DateTime focusedMonth = DateTime.now();
  late Map<DateTime, String> attendanceMap;
  late Map<String, EmployeeModel> employeeMap;
  String? currentUserId;
  late List<AttendanceModel> filteredList;
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    employeeMap = {for (var e in widget.employees) e.employeeId: e};

    filteredList = widget.attendanceList;
    attendanceMap = _buildAttendanceMap();
    _loadUser();
  }

  @override
  void didUpdateWidget(covariant _AttendanceCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.attendanceList != widget.attendanceList) {
      setState(() {
        attendanceMap = _buildAttendanceMap();
      });
    }
  }

  Future<void> _loadUser() async {
    final uid = await Spdb.getUid();
    setState(() {
      currentUserId = uid;
    });
  }

  Map<DateTime, String> _buildAttendanceMap() {
    final map = <DateTime, String>{};

    for (var a in widget.attendanceList) {
      if (widget.userType == UserType.employee &&
          a.employeeId != widget.employeeId) {
        continue;
      }

      if (a.punchList.isEmpty) continue;

      var punch = a.punchList.first;
      final date = _parseDate(punch.punchDate);
      if (date == null) continue;

      String status = getAttendanceStatus(punch);

      if (a.permissionDetails.isNotEmpty) {
        final key = DateFormat('yyyy-MM-dd').format(date);
        final permission = a.permissionDetails[key];

        if (permission != null) {
          status = permission.name;
        }
      }

      map[DateTime(date.year, date.month, date.day)] = status;
    }

    return map;
  }

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

  // IconData _getStatusIcon(String? status) {
  //   switch (status) {
  //     case "Present":
  //       return Icons.check_circle;

  //     case "Absent":
  //       return Icons.cancel;

  //     case "Leave":
  //       return Icons.beach_access;

  //     case "HalfDay":
  //       return Icons.timelapse;

  //     case "WFH":
  //       return Icons.home;

  //     case "Late":
  //       return Icons.access_time;

  //     case "EarlyExit":
  //       return Icons.logout;

  //     case "Pending":
  //       return Icons.hourglass_empty;

  //     case "Permission":
  //       return Icons.verified;

  //     case "Rejected":
  //       return Icons.block;

  //     default:
  //       return Icons.circle;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: TableCalendar(
                    firstDay: DateTime(2025, 1, 1),
                    lastDay: DateTime(2027, 12, 31),
                    focusedDay: focusedMonth,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(.5),
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
                            attendanceMap[DateTime(
                              day.year,
                              day.month,
                              day.day,
                            )];
                        final isSelected =
                            selectedDay != null &&
                            day.year == selectedDay!.year &&
                            day.month == selectedDay!.month &&
                            day.day == selectedDay!.day;

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

                          case "Pending":
                            markerColor = Colors.grey;
                            break;

                          case "Permission":
                            markerColor = Colors.teal;
                            break;

                          case "Rejected":
                            markerColor = Colors.black45;
                            break;
                        }

                        bool isToday =
                            day.year == DateTime.now().year &&
                            day.month == DateTime.now().month &&
                            day.day == DateTime.now().day;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(6),
                          transform: Matrix4.identity()
                            ..scale(
                              isSelected
                                  ? 1.12
                                  : isToday
                                  ? 1.04
                                  : 1.0,
                            ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            color: isSelected
                                ? Colors.deepPurple
                                : isToday
                                ? Colors.transparent
                                : Colors.white,

                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : isToday
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              width: isSelected
                                  ? 2.5
                                  : isToday
                                  ? 2
                                  : 1,
                            ),

                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              else if (isToday)
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              else
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  "${day.day}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    // fontSize: isSelected ? 16 : 14,
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                              ),

                              if (isToday && !isSelected)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (markerColor != null)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    width: isSelected ? 10 : 8,
                                    height: isSelected ? 10 : 8,
                                    decoration: BoxDecoration(
                                      color: markerColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    onDaySelected: (selected, focusedDay) {
                      setState(() {
                        selectedDay = selected;
                        focusedMonth = focusedDay;
                      });

                      final status =
                          attendanceMap[DateTime(
                            selected.year,
                            selected.month,
                            selected.day,
                          )];

                      if (status == null) return;

                      final attendance = widget.attendanceList.firstWhere(
                        (e) => e.employeeId == widget.employeeId,
                        orElse: () => widget.attendanceList.first,
                      );

                      if (widget.userType == UserType.admin) {
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          builder: (_) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selected),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  _buildDetailRow("Status", status),
                                  _buildDetailRow(
                                    "Work",
                                    attendance.formattedWork,
                                  ),
                                  _buildDetailRow(
                                    "Break",
                                    attendance.formattedBreak,
                                  ),
                                  _buildDetailRow("OT", attendance.formattedOT),
                                  _buildDetailRow(
                                    "Less",
                                    attendance.formattedLess,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          builder: (_) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selected),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Text("Status: $status"),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
