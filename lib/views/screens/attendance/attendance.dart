import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/department_model.dart';
import 'package:leadcapture/models/src/employee_model.dart';
import 'package:leadcapture/models/src/user_data_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';
import 'package:leadcapture/services/firebase/src/employee_service.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/screens/attendance/attendance_helper.dart';
import 'package:leadcapture/views/screens/attendance/employee_report.dart';
import 'package:leadcapture/views/screens/permission/src/permisson_create.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:table_calendar/table_calendar.dart';

DateTime? parseDateTime(dynamic time) {
  if (time == null) return null;

  if (time is int) {
    return DateTime.fromMillisecondsSinceEpoch(time);
  } else if (time is String) {
    return DateTime.tryParse(time);
  } else if (time.runtimeType.toString() == 'Timestamp') {
    return time.toDate();
  }

  return null;
}

const String _pageTitle = "Attendance";

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance>
    with SingleTickerProviderStateMixin {
  late Future aHandler;
  UserDataModel? user;
  final TextEditingController _search = TextEditingController();
  String selectedStatus = "All";
  String selectedType = "All";
  DateTimeRange? selectedDateRange;
  String dateRangeText = "Select Date Range";

  List<AttendanceModel> aList = [];
  List<AttendanceModel> filteredList = [];
  final List<AttendanceModel> tempAList = [];
  final List<EmployeeModel> employees = [];
  final List<DepartmentModel> departments = [];
  String selectedEmployee = "All";
  String selectedDepartment = "All";
  AttendanceStats? stats;
  bool isAdmin = false;
  bool isEmployee = false;
  String selectedSummaryFilter = "All";
  Map<String, EmployeeModel> employeeMap = {};
  late TabController tabController;
  Timer? _timer;
  List<WorktimeModel> workList = [];

  @override
  void initState() {
    super.initState();
    aHandler = init();
    tabController = TabController(length: 3, vsync: this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  Future<void> init() async {
    user = await Spdb.getUser();
    isAdmin = await Spdb.isAdminLoggedIn();
    isEmployee = await Spdb.isEmployeeLoggedIn();
    if (isAdmin) {
      employees.clear();
      employees.addAll(await EmployeeService.getAllEmployees());

      employeeMap = {for (var emp in employees) emp.uid!: emp};
    }

    DateTime now = DateTime.now();
    DateTime fromDate = DateTime(now.year, now.month, 1);
    DateTime toDate = DateTime(now.year, now.month + 1, 0);

    stats = await AttendanceService.getAttendanceStats(
      userUid: user!.userType == UserType.employee ? user!.uid : "",
      fromDate: fromDate,
      toDate: toDate,
    );

    if (isAdmin) {
      workList = await WorktimeService.dashboardWorktimeListing(
        date: DateTime.now(),
      );
    } else {
      workList = await WorktimeService.userWorktimeListing(userId: user!.uid);
    }
    aList.clear();
    tempAList.clear();

    aList.addAll(stats!.attendanceData);

    for (var work in workList) {
      final workAttendance = attendanceWorktime(work);

      final index = aList.indexWhere((a) {
        if (a.punchList.isEmpty || workAttendance.punchList.isEmpty) {
          return false;
        }

        final aDate = parseDateTime(a.punchList.first.punchDate);
        final wDate = parseDateTime(workAttendance.punchList.first.punchDate);

        return a.employeeId == workAttendance.employeeId &&
            aDate?.year == wDate?.year &&
            aDate?.month == wDate?.month &&
            aDate?.day == wDate?.day;
      });

      if (index != -1) {
        final existingPunch = aList[index].punchList.first;
        final workPunch = workAttendance.punchList.first;

        existingPunch.clockIn = workPunch.clockIn;
        existingPunch.clockOut = workPunch.clockOut;
        existingPunch.punchTime = workPunch.punchTime;
      } else {
        aList.add(workAttendance);
      }
    }

    tempAList.addAll(aList);
    filteredList = List.from(aList);
    stats = calculateStats(filteredList);
    tempAList.addAll(aList);

    filteredList = List.from(aList);
    stats = calculateStats(filteredList);

    aList.sort((a, b) {
      if (a.punchList.isEmpty || b.punchList.isEmpty) return 0;

      final dateA = parseDateTime(a.punchList.first.punchDate);
      final dateB = parseDateTime(b.punchList.first.punchDate);

      if (dateA == null || dateB == null) return 0;

      return dateB.compareTo(dateA);
    });
  }

  List<DropdownMenuItem<String>> _employeeItems() {
    return [
      const DropdownMenuItem(value: "All", child: Text("All")),
      ...employees.map(
        (e) => DropdownMenuItem(value: e.uid, child: Text(e.name)),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _departmentItems() {
    return [
      const DropdownMenuItem(value: "All", child: Text("All")),
      ...departments.map(
        (d) => DropdownMenuItem(value: d.uid, child: Text(d.name)),
      ),
    ];
  }

  void _onEmployeeChanged(String? val) {
    setState(() {
      selectedEmployee = val!;
      applyFilters();
    });
  }

  void _onDepartmentChanged(String? val) {
    setState(() {
      selectedDepartment = val!;
      applyFilters();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        dateRangeText =
            "${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM').format(picked.end)}";
        applyFilters();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      selectedEmployee = "All";
      selectedDepartment = "All";
      selectedStatus = "All";
      selectedDateRange = null;
      dateRangeText = "Select Date Range";
      applyFilters();
    });
  }

  String formatTime(int? time) {
    if (time == null) return "-";
    final dt = DateTime.fromMillisecondsSinceEpoch(time);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  bool isToday0(AttendanceModel a) {
    if (a.punchList.isEmpty) return false;

    final date = parseDateTime(a.punchList.first.punchDate);
    if (date == null) return false;

    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  EmployeeModel? findEmployee(String uid) {
    try {
      return employees.firstWhere((e) => e.uid == uid);
    } catch (_) {
      return null;
    }
  }

  Map<String, List<AttendanceModel>> groupByEmployee() {
    final Map<String, List<AttendanceModel>> grouped = {};

    for (var a in filteredList) {
      grouped.putIfAbsent(a.employeeId, () => []).add(a);
    }

    return grouped;
  }

  Color statusColor(String status) {
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

      case "Pending":
        return Colors.orange;

      case "Rejected":
        return Colors.redAccent;

      case "LessHours":
        return Colors.brown;

      case "InProgress":
        return Colors.blueGrey;

      default:
        return Colors.grey;
    }
  }

  void applySummaryFilter(String label) {
    setState(() {
      selectedSummaryFilter = label;

      if (label == "All") {
        filteredList = List.from(tempAList);
        return;
      }

      filteredList = tempAList.where((a) {
        if (a.punchList.isEmpty) return false;

        final status = getAttendanceStatus(a);

        switch (label) {
          case "Present":
            return status == "Present";

          case "Absent":
            return status == "Absent";

          case "Leave":
            return status == "Leave";

          case "WFH":
            return status == "WFH";

          case "Half Day":
            return status == "HalfDay";

          case "Late":
            return status == "Late";

          case "Early Exit":
            return status == "EarlyExit";

          default:
            return true;
        }
      }).toList();
    });
  }

  void sortByName(bool asc) {
    setState(() {
      filteredList.sort((a, b) {
        final nameA = findEmployee(a.employeeId)?.name ?? "";
        final nameB = findEmployee(b.employeeId)?.name ?? "";
        return asc ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
      });
    });
  }

  void sortByDate(bool asc) {
    setState(() {
      filteredList.sort((a, b) {
        final d1 = parseDateTime(a.punchList.first.punchDate) ?? DateTime.now();
        final d2 = parseDateTime(b.punchList.first.punchDate) ?? DateTime.now();
        return asc ? d1.compareTo(d2) : d2.compareTo(d1);
      });
    });
  }

  void sortByStatus(bool asc) {
    setState(() {
      filteredList.sort((a, b) {
        final s1 = getAttendanceStatus(a);
        final s2 = getAttendanceStatus(b);
        return asc ? s1.compareTo(s2) : s2.compareTo(s1);
      });
    });
  }

  void showAttendanceDetails(AttendanceModel a) {
    final punch = a.punchList.first;
    final status = getAttendanceStatus(a);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String checkIn = punch.clockIn != null
            ? formatTime(punch.clockIn)
            : "-";

        String checkOut = punch.clockOut != null
            ? formatTime(punch.clockOut)
            : "-";

        final date = parseDateTime(punch.punchDate);

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
                  color: statusColor(status).withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor(status),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  infoTile(Iconsax.login, "Check In", checkIn),
                  infoTile(Iconsax.logout, "Check Out", checkOut),
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
                    infoTile(Iconsax.clock, "Work", a.formattedWork),
                    infoTile(Iconsax.pause, "Break", a.formattedBreak),
                    infoTile(Iconsax.flash, "OT", a.formattedOT),
                    infoTile(Iconsax.warning_2, "Less", a.formattedLess),
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
    List<AttendanceModel> filtered = tempAList.where((a) {
      if (a.punchList.isEmpty) return false;
      final punch = a.punchList.first;
      final status = getAttendanceStatus(a);
      final type = punch.permissionType?.name ?? "";

      bool matchesEmployee = selectedEmployee == "All"
          ? true
          : a.employeeId == selectedEmployee;

      bool matchesDepartment = true;
      if (selectedDepartment != "All") {
        EmployeeModel? emp;
        try {
          emp = employees.firstWhere((e) => e.uid == a.employeeId);
        } catch (_) {
          emp = null;
        }
        matchesDepartment =
            emp?.department?.contains(selectedDepartment) ?? false;
      }
      bool matchesStatus = selectedStatus == "All"
          ? true
          : status.toLowerCase() == selectedStatus.toLowerCase();
      bool matchesType = selectedType == "All" ? true : type == selectedType;
      bool matchesDate = true;

      if (selectedDateRange != null) {
        final punchDate = parseDateTime(punch.punchDate);
        if (punchDate == null) return false;
        matchesDate =
            !punchDate.isBefore(selectedDateRange!.start) &&
            !punchDate.isAfter(selectedDateRange!.end);
      }

      return matchesEmployee &&
          matchesDepartment &&
          matchesStatus &&
          matchesType &&
          matchesDate;
    }).toList();

    setState(() {
      filteredList = filtered;

      stats = calculateStats(filteredList);
    });
  }

  AttendanceStats calculateStats(List<AttendanceModel> list) {
    int present = 0;
    int absent = 0;
    int leave = 0;
    int wfh = 0;
    int halfDay = 0;
    int late = 0;
    int earlyExit = 0;

    for (var a in list) {
      if (a.punchList.isEmpty) {
        absent++;
        continue;
      }
      final status = getAttendanceStatus(a);

      switch (status) {
        case "Present":
          present++;
          break;
        case "Absent":
          absent++;
          break;
        case "Leave":
          leave++;
          break;
        case "WFH":
          wfh++;
          break;
        case "HalfDay":
          halfDay++;
          break;
        case "Late":
          late++;
          break;
        case "EarlyExit":
          earlyExit++;
          break;
      }
    }

    return AttendanceStats(
      presentDays: present,
      absentDays: absent,
      leaveDays: leave,
      wfhDays: wfh,
      halfDayDays: halfDay,
      lateDays: late,
      earlyExitDays: earlyExit,
      totalWorkingHours: "0",
      totalOTHours: "0",
      totalLessHours: "0",
      attendanceData: list,
    );
  }

  void onDayTap(DateTime date) {
    final aListForDay = aList.where((e) {
      if (e.punchList.isEmpty) return false;

      final parsedDate = parseDateTime(e.punchList.first.punchDate);
      if (parsedDate == null) return false;

      return parsedDate.year == date.year &&
          parsedDate.month == date.month &&
          parsedDate.day == date.day;
    }).toList();

    if (aListForDay.isNotEmpty) {
      showAttendanceDetails(aListForDay.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance record for this day')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = aList.any(
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
          aHandler = init();
          setState(() {});
        },
        child: FutureBuilder<void>(
          future: aHandler,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            }
            return isAdmin ? buildAdminView() : buildEmployeeView();
          },
        ),
      ),
    );
  }

  Widget buildAdminView() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade50,
                  child: Column(
                    children: [
                      // todayAdminSummary(),
                      const SizedBox(height: 10),
                      buildSummaryCards(stats!),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: permissionApprovalPanel()),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: filterPanel(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: adminActionBar(),
                ),
              ),

              SliverFillRemaining(
                hasScrollBody: true,
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      /// 🔹 TAB BAR (Fixed)
                      Material(
                        color: Colors.white,
                        child: TabBar(
                          controller: tabController,
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorWeight: 3,
                          tabs: const [
                            // Tab(text: "Employee"),
                            Tab(text: "Calendar"),
                            Tab(text: "Table"),
                          ],
                        ),
                      ),

                      /// 🔹 TAB CONTENT (Scrollable per tab)
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: [
                            // attendanceAdminView(),
                            attendanceCalendar(),
                            attendanceTableView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget attendanceCalendar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _AttendanceCalendar(
        attendanceList: filteredList,
        userType: user!.userType,
        employeeId: selectedEmployee,
        employees: employees,
        departments: departments,
        onDayTap: onDayTap,
      ),
    );
  }

  Widget buildEmployeeView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              todaySummary(),
              const SizedBox(height: 10),
              buildSummaryCards(stats!),
            ],
          ),
        ),

        TabBar(
          controller: tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Calendar"),
            Tab(text: "List"),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _AttendanceCalendar(
                  attendanceList: filteredList,
                  userType: user!.userType,
                  employeeId: user!.uid,
                  employees: employees,
                  departments: departments,
                  onDayTap: onDayTap,
                ),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: attendanceListView(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget infoTile(IconData icon, String label, String minutes) {
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

  Widget permissionApprovalPanel() {
    final pendingPermissions = aList
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Iconsax.warning_2, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      "Pending Requests",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pendingPermissions.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...pendingPermissions.map((a) {
              final punch = a.punchList.first;
              final date = parseDateTime(punch.punchDate);
              final emp = findEmployee(a.employeeId);

              final checkIn = punch.clockIn != null
                  ? formatTime(punch.clockIn)
                  : "-";
              final checkOut = punch.clockOut != null
                  ? formatTime(punch.clockOut)
                  : "-";

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  /// 👤 EMPLOYEE INFO
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      emp?.name.substring(0, 1).toUpperCase() ?? "?",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  title: Text(
                    emp?.name ?? "Unknown Employee",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      /// Permission Type
                      Text(
                        punch.permissionType!.name,
                        style: const TextStyle(fontSize: 12),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Iconsax.calendar,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date != null
                                ? DateFormat('dd MMM yyyy').format(date)
                                : "--",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// ⏰ TIME
                      Row(
                        children: [
                          const Icon(
                            Iconsax.login,
                            size: 13,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(checkIn, style: const TextStyle(fontSize: 11)),

                          const SizedBox(width: 10),

                          const Icon(
                            Iconsax.logout,
                            size: 13,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(checkOut, style: const TextStyle(fontSize: 11)),
                        ],
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Approved"),
                              duration: Duration(milliseconds: 800),
                            ),
                          );

                          await AttendanceService.updatePermissionStatus(
                            punchId: punch.uid!,
                            status: PermissionsStatus.approved,
                          );

                          aHandler = init();
                          setState(() {});
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Rejected"),
                              duration: Duration(milliseconds: 800),
                            ),
                          );

                          await AttendanceService.updatePermissionStatus(
                            punchId: punch.uid!,
                            status: PermissionsStatus.rejected,
                          );

                          aHandler = init();
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

  Widget buildSummaryCards(AttendanceStats stats) {
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

          return summaryCard(
            label: item.$1,
            value: item.$2,
            color: item.$3,
            width: screenWidth * 0.19,
          );
        },
      ),
    );
  }

  Widget summaryCard({
    required String label,
    required String value,
    required Color color,
    required double width,
  }) {
    final bool isPrimary = label == "Present" || label == "Absent";
    final bool isSelected = selectedSummaryFilter == label;

    return GestureDetector(
      onTap: () {
        applySummaryFilter(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(.25)
              : isPrimary
              ? color.withOpacity(.12)
              : Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: isSelected
                ? color
                : isPrimary
                ? color.withOpacity(.4)
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),

          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(.4)
                  : Colors.black.withOpacity(.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(getSummaryIcon(label), color: color, size: 25),
            ),
            const SizedBox(width: 10),
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
      ),
    );
  }

  IconData getSummaryIcon(String label) {
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

  Widget filterPanel() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filters",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                /// 🔁 RESET (Top Right - Better UX)
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Reset"),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// 🔽 DROPDOWNS (Responsive)
            isMobile
                ? Column(
                    children: [
                      _buildDropdown(
                        label: "Employee",
                        value: selectedEmployee,
                        items: _employeeItems(),
                        onChanged: _onEmployeeChanged,
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        label: "Department",
                        value: selectedDepartment,
                        items: _departmentItems(),
                        onChanged: _onDepartmentChanged,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: "Employee",
                          value: selectedEmployee,
                          items: _employeeItems(),
                          onChanged: _onEmployeeChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: "Department",
                          value: selectedDepartment,
                          items: _departmentItems(),
                          onChanged: _onDepartmentChanged,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 16),

            /// 🎯 STATUS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Status",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),

                /// 📅 DATE PICKER (Aligned Right)
                OutlinedButton.icon(
                  icon: const Icon(Iconsax.calendar, size: 16),
                  label: Text(dateRangeText, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _pickDateRange,
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// 🎯 FILTER CHIPS
            buildFilterChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Widget buildFilterChips() {
    final filters = [
      "All",
      "Present",
      "Absent",
      "Leave",
      "WFH",
      "Late",
      "EarlyExit",
      "HalfDay",
      "Pending",
      "Rejected",
      "LessHours",
      "InProgress",
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final isSelected = selectedStatus == f;

        return ChoiceChip(
          label: Text(f),
          selected: isSelected,
          selectedColor: statusColor(f).withOpacity(0.2),
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isSelected ? statusColor(f) : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) {
            setState(() {
              selectedStatus = f;
              applyFilters();
            });
          },
        );
      }).toList(),
    );
  }

  Widget attendanceListView() {
    String formatPermission(PermissionType type) {
      switch (type) {
        case PermissionType.leaveFullDay:
          return "Full Day Leave";
        case PermissionType.leaveHalfDay:
          return "Half Day";
        case PermissionType.workFromHome:
          return "Work From Home";
        case PermissionType.lateEntry:
          return "Late Entry";
        case PermissionType.earlyExit:
          return "Early Exit";
        case PermissionType.permission:
          return "Permission";
      }
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Iconsax.calendar_remove, size: 50, color: Colors.grey),
              const SizedBox(height: 10),
              const Text("No Attendance Found"),
              const SizedBox(height: 5),
              const Text(
                "Try changing filters or date range",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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
        final emp = employeeMap[a.employeeId];
        final punch = a.punchList.first;
        final status = getAttendanceStatus(a);
        final color = statusColor(status);
        final date = parseDateTime(punch.punchDate);

        final isToday =
            date != null &&
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        final checkIn = punch.clockIn != null ? formatTime(punch.clockIn) : "-";

        final checkOut = punch.clockOut != null
            ? formatTime(punch.clockOut)
            : "-";

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showAttendanceDetails(a),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Card(
              elevation: 1,
              color: isToday ? Colors.blue[50] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdmin && emp != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: emp.profileImageUrl != null
                                ? NetworkImage(emp.profileImageUrl!)
                                : null,
                            child: emp.profileImageUrl == null
                                ? Text(
                                    emp.name.isNotEmpty
                                        ? emp.name[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  emp.department != null &&
                                          emp.department!.isNotEmpty
                                      ? emp.department!.first
                                      : "No Department",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          buildStatusChip(status),
                        ],
                      ),
                    if (isAdmin) const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withOpacity(.15),
                          child: Text(
                            date != null ? DateFormat('dd').format(date) : "--",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date != null
                                    ? DateFormat(
                                        'EEE, MMM dd yyyy',
                                      ).format(date)
                                    : "--",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.login,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    checkIn,
                                    style: const TextStyle(fontSize: 11),
                                  ),

                                  const SizedBox(width: 12),

                                  const Icon(
                                    Iconsax.logout,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    checkOut,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isAdmin) buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        miniStat("Work", a.formattedWork, Colors.blue),
                        miniStat("Break", a.formattedBreak, Colors.orange),
                        miniStat("OT", a.formattedOT, Colors.green),
                        miniStat("Less", a.formattedLess, Colors.red),
                      ],
                    ),
                    if (punch.permissionType != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.warning_2,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${formatPermission(punch.permissionType!)} • ${punch.permissionStatus!.name.toUpperCase()}",
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget attendanceTableView() {
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar_remove,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text("No Attendance Data"),
            const SizedBox(height: 5),
            const Text(
              "Try adjusting filters or search",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        /// 🔍 ENHANCED SEARCH
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6),
              ],
            ),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: "Search employee or status...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() {
                            filteredList = tempAList;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  filteredList = tempAList.where((a) {
                    final emp = findEmployee(a.employeeId);
                    final name = emp?.name.toLowerCase() ?? "";
                    final status = getAttendanceStatus(a).toLowerCase();

                    return name.contains(value.toLowerCase()) ||
                        status.contains(value.toLowerCase());
                  }).toList();
                });
              },
            ),
          ),
        ),

        /// 📊 TABLE CONTAINER
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 28,
                    dataRowHeight: 64,
                    headingRowHeight: 56,

                    headingRowColor: WidgetStateProperty.all(
                      Colors.blue.shade50,
                    ),

                    columns: [
                      DataColumn(
                        label: const Text("Employee"),
                        onSort: (i, asc) => sortByName(asc),
                      ),
                      DataColumn(
                        label: const Text("Date"),
                        onSort: (i, asc) => sortByDate(asc),
                      ),
                      const DataColumn(label: Text("In")),
                      const DataColumn(label: Text("Out")),
                      const DataColumn(label: Text("Work")),
                      DataColumn(
                        label: const Text("Status"),
                        onSort: (i, asc) => sortByStatus(asc),
                      ),
                      const DataColumn(label: Text("Action")),
                    ],

                    rows: List.generate(filteredList.length, (index) {
                      final a = filteredList[index];
                      final emp = findEmployee(a.employeeId);
                      final punch = a.punchList.first;

                      final status = getAttendanceStatus(a);
                      final color = statusColor(status);
                      final date = parseDateTime(punch.punchDate);

                      final checkIn = punch.clockIn != null
                          ? formatTime(punch.clockIn)
                          : "-";

                      final checkOut = punch.clockOut != null
                          ? formatTime(punch.clockOut)
                          : "-";

                      final baseColor = index % 2 == 0
                          ? Colors.white
                          : Colors.grey.shade50;

                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.blue.withOpacity(0.08);
                          }
                          return baseColor;
                        }),

                        cells: [
                          /// 👤 EMPLOYEE
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: color.withOpacity(.15),
                                  child: Text(
                                    emp?.name.substring(0, 1).toUpperCase() ??
                                        "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  emp?.name ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// 📅 DATE
                          DataCell(
                            Text(
                              date != null
                                  ? DateFormat('dd MMM yyyy').format(date)
                                  : "--",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),

                          /// ⏰ IN / OUT
                          DataCell(Text(checkIn)),
                          DataCell(Text(checkOut)),

                          /// ⏱ WORK
                          DataCell(
                            Text(
                              a.formattedWork,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          /// 🚦 STATUS CHIP
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          /// ⚡ ACTIONS
                          DataCell(
                            Row(
                              children: [
                                if (punch.permissionStatus ==
                                    PermissionsStatus.pending) ...[
                                  IconButton(
                                    tooltip: "Approve",
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      await AttendanceService.updatePermissionStatus(
                                        punchId: punch.uid!,
                                        status: PermissionsStatus.approved,
                                      );
                                      aHandler = init();
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    tooltip: "Reject",
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await AttendanceService.updatePermissionStatus(
                                        punchId: punch.uid!,
                                        status: PermissionsStatus.rejected,
                                      );
                                      aHandler = init();
                                      setState(() {});
                                    },
                                  ),
                                ] else
                                  const Text("-"),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget attendanceAdminView() {
    if (selectedEmployee == "All") {
      return const Center(
        child: Text("Please select an employee to view details"),
      );
    }

    final employeeAttendance = filteredList
        .where((a) => a.employeeId == selectedEmployee)
        .toList();

    if (employeeAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.folder_open, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text("No Data Found"),
            const SizedBox(height: 5),
            const Text(
              "Try changing filters",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final emp = employeeMap[selectedEmployee];
    final empStats = calculateStats(employeeAttendance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  emp?.name.substring(0, 1).toUpperCase() ?? "?",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp?.name ?? "",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    emp?.department?.first ?? "No Department",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ⚡ ACTIONS
          Row(
            children: [
              ElevatedButton(
                child: const Text("View Report"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EmployeeReport(employeeId: selectedEmployee),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              OutlinedButton(child: const Text("Mark Leave"), onPressed: () {}),
            ],
          ),

          const SizedBox(height: 16),

          /// 📊 SUMMARY
          buildSummaryCards(empStats),

          const SizedBox(height: 16),

          /// 📅 CALENDAR
          _AttendanceCalendar(
            attendanceList: employeeAttendance,
            userType: user!.userType,
            employeeId: selectedEmployee,
            employees: employees,
            departments: departments,
            onDayTap: onDayTap,
          ),
        ],
      ),
    );
  }

  Widget adminActionBar() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Actions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: _exportButton()),
                    const SizedBox(width: 10),
                    Expanded(child: _refreshButton()),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Actions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                Row(
                  children: [
                    _exportButton(),
                    const SizedBox(width: 10),
                    _refreshButton(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _exportButton() {
    return Tooltip(
      message: "Export attendance data",
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // TODO: Export logic
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          // decoration: BoxDecoration(
          //   border: Border.all(color: Colors.green),
          //   borderRadius: BorderRadius.circular(10),
          // ),
          child: const Icon(Icons.download, size: 20, color: Colors.green),
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return Tooltip(
      message: "Refresh attendance",
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          setState(() {
            aHandler = init();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          // decoration: BoxDecoration(
          //   color: Colors.blue,
          //   borderRadius: BorderRadius.circular(10),
          // ),
          child: const Icon(
            Icons.refresh,
            size: 20,
            color: Colors.lightBlueAccent,
          ),
        ),
      ),
    );
  }

  Widget miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget buildStatusChip(String status) {
    final color = statusColor(status);
    final icon = getSummaryIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(.15), color.withOpacity(.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget todaySummary() {
    AttendanceModel? today;
    try {
      today = aList.firstWhere((a) => isToday0(a));
    } catch (_) {
      today = null;
    }
    if (today == null || today.punchList.isEmpty) {
      return const SizedBox();
    }
    final punch = today.punchList.first;
    final status = getAttendanceStatus(today);
    final color = statusColor(status);
    final hasCheckIn = punch.clockIn != null;
    final hasCheckOut = punch.clockOut != null;
    final checkIn = formatTime(punch.clockIn);
    final checkOut = hasCheckOut
        ? formatTime(punch.clockOut)
        : (hasCheckIn ? "Working..." : "--");
    double getProgress() {
      return (today!.workingHourMinutes / 480).clamp(0.0, 1.0);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(getSummaryIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Attendance",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Work",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      today.formattedWork,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeTile(Iconsax.login, "Check In", checkIn, Colors.green),
                _timeTile(
                  Iconsax.logout,
                  "Check Out",
                  checkOut,
                  hasCheckOut ? Colors.red : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: getProgress(),
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // Widget todayAdminSummary() {
  //   final todayList = aList.where((a) => isToday0(a)).toList();

  //   if (todayList.isEmpty) return const SizedBox();

  //   int present = 0;
  //   int absent = 0;
  //   int late = 0;

  //   for (var a in todayList) {
  //     final status = getAttendanceStatus(a);

  //     if (status == "Present") present++;
  //     if (status == "Absent") absent++;
  //     if (status == "Late") late++;
  //   }

  //   return Container(
  //     margin: const EdgeInsets.all(12),
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.blue.withOpacity(.2)),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _miniTodayTile("Present", present.toString(), Colors.green),
  //         _miniTodayTile("Absent", absent.toString(), Colors.red),
  //         _miniTodayTile("Late", late.toString(), Colors.orange),
  //       ],
  //     ),
  //   );
  // }

  // Widget _miniTodayTile(String label, String value, Color color) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: TextStyle(
  //           fontWeight: FontWeight.bold,
  //           fontSize: 16,
  //           color: color,
  //         ),
  //       ),
  //       Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  //     ],
  //   );
  // }
}

class EmployeeInfoWidget extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeInfoWidget({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: employee.profileImageUrl != null
              ? NetworkImage(employee.profileImageUrl!)
              : null,
          child: employee.profileImageUrl == null
              ? Text(
                  employee.name.isNotEmpty
                      ? employee.name[0].toUpperCase()
                      : "?",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              employee.name,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 2),

            Text(
              employee.department != null && employee.department!.isNotEmpty
                  ? employee.department!.join(", ")
                  : "No Department",
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ],
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
  String? currentUserId;
  late List<AttendanceModel> filteredList;
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    _applyFilter();
    // filteredList = widget.attendanceList;
    // attendanceMap = _buildAttendanceMap();
    _loadUser();
  }

  @override
  void didUpdateWidget(covariant _AttendanceCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.attendanceList != widget.attendanceList) {
      setState(() {
        // attendanceMap = _buildAttendanceMap();
        _applyFilter();
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

    for (var a in filteredList) {
      if (a.punchList.isEmpty) continue;

      final punch = a.punchList.first;
      final date = parseDateTime(punch.punchDate);
      if (date == null) continue;

      String status = getAttendanceStatus(a);
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

  // Map<DateTime, String> _buildAttendanceMap() {
  //   final map = <DateTime, String>{};

  //   for (var a in widget.attendanceList) {
  //     if (widget.userType == UserType.employee &&
  //         a.employeeId != widget.employeeId) {
  //       continue;
  //     }
  //     if (widget.userType == UserType.admin &&
  //         widget.employeeId != "All" &&
  //         a.employeeId != widget.employeeId) {
  //       continue;
  //     }
  //     if (a.punchList.isEmpty) continue;

  //     var punch = a.punchList.first;
  //     final date = parseDateTime(punch.punchDate);
  //     if (date == null) continue;

  //     String status = getAttendanceStatus(a);

  //     if (a.permissionDetails.isNotEmpty) {
  //       final key = DateFormat('yyyy-MM-dd').format(date);
  //       final permission = a.permissionDetails[key];

  //       if (permission != null) {
  //         status = permission.name;
  //       }
  //     }

  //     map[DateTime(date.year, date.month, date.day)] = status;
  //   }

  //   return map;
  // }

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

  bool isWeekend(DateTime day) {
    return day.weekday == DateTime.sunday;
  }

  void _applyFilter() {
    if (widget.userType == UserType.employee) {
      // 👤 Employee → only own data
      filteredList = widget.attendanceList
          .where((a) => a.employeeId == widget.employeeId)
          .toList();
    } else if (widget.userType == UserType.admin &&
        widget.employeeId != null &&
        widget.employeeId != "All") {
      // 👨‍💼 Admin → selected employee
      filteredList = widget.attendanceList
          .where((a) => a.employeeId == widget.employeeId)
          .toList();
    } else {
      // 👨‍💼 Admin → All employees
      filteredList = widget.attendanceList;
    }

    attendanceMap = _buildAttendanceMap();
  }

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
                        final isWeekendDay = isWeekend(day);
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
                                : isWeekendDay
                                ? Colors.red.withOpacity(0.05)
                                : isToday
                                ? Colors.blue.withOpacity(0.08)
                                : Colors.transparent,

                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : isWeekendDay
                                  ? Colors.red.withOpacity(0.4)
                                  : isToday
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: isSelected
                                  ? 2
                                  : isWeekendDay
                                  ? 1.5
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
                                    color: isSelected
                                        ? Colors.white
                                        : isWeekendDay
                                        ? Colors.redAccent
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
                      final attendance = filteredList.firstWhere((e) {
                        if (e.punchList.isEmpty) return false;

                        final d = parseDateTime(e.punchList.first.punchDate);

                        return d?.year == selected.year &&
                            d?.month == selected.month &&
                            d?.day == selected.day;
                      }, orElse: () => filteredList.first);
                      // final attendance = widget.attendanceList.firstWhere((e) {
                      //   if (e.punchList.isEmpty) return false;

                      //   final d = parseDateTime(e.punchList.first.punchDate);

                      //   return e.employeeId == widget.employeeId &&
                      //       d?.year == selected.year &&
                      //       d?.month == selected.month &&
                      //       d?.day == selected.day;
                      // }, orElse: () => widget.attendanceList.first);

                      final dayRecords = filteredList.where((e) {
                        if (e.punchList.isEmpty) return false;

                        final d = parseDateTime(e.punchList.first.punchDate);

                        return d?.year == selected.year &&
                            d?.month == selected.month &&
                            d?.day == selected.day;
                      }).toList();

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

                                  if (widget.employeeId == "All") ...[
                                    Text("Total Records: ${dayRecords.length}"),
                                    const SizedBox(height: 10),

                                    ...dayRecords.take(5).map((e) {
                                      final emp = widget.employees.firstWhere(
                                        (emp) => emp.uid == e.employeeId,
                                      );

                                      return _buildDetailRow(
                                        emp.name,
                                        getAttendanceStatus(e),
                                      );
                                    }),
                                  ] else ...[
                                    _buildDetailRow("Status", status),
                                    _buildDetailRow(
                                      "Work",
                                      attendance.formattedWork,
                                    ),
                                    _buildDetailRow(
                                      "Break",
                                      attendance.formattedBreak,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) {
                            return DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: 0.4,
                              minChildSize: 0.3,
                              maxChildSize: 0.7,
                              builder: (context, scrollController) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ListView(
                                    controller: scrollController,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 5,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(selected),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _infoCard(
                                        title: "Status",
                                        value: status,
                                        icon: Icons.info,
                                        color: _statusColor(status),
                                      ),
                                      const SizedBox(height: 10),
                                      _infoCard(
                                        title: "Work Hours",
                                        value: attendance.formattedWork,
                                        icon: Icons.access_time,
                                      ),
                                      _infoCard(
                                        title: "Break Time",
                                        value: attendance.formattedBreak,
                                        icon: Icons.free_breakfast,
                                      ),
                                    ],
                                  ),
                                );
                              },
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

  Color _statusColor(String status) {
    switch (status) {
      case "Present":
        return Colors.green;
      case "Absent":
        return Colors.red;
      case "Leave":
        return Colors.orange;
      case "HalfDay":
        return Colors.amber;
      case "WFH":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (color ?? Colors.blue).withOpacity(0.1),
            child: Icon(icon, size: 18, color: color ?? Colors.blue),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),

          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
