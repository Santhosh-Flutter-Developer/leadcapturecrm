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
import 'package:leadcapture/services/firebase/src/employee_service.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/screens/permission/src/permisson_create.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:table_calendar/table_calendar.dart';

String getAttendanceStatus(PunchModel punch) {
  final type = punch.permissionType;
  final status = punch.permissionStatus;

  /// 🔴 PRIORITY 1: Pending
  if (status == PermissionsStatus.pending) return "Pending";

  /// 🔴 PRIORITY 2: Rejected
  if (status == PermissionsStatus.rejected) return "Rejected";

  /// 🟢 PRIORITY 3: Approved Permission Overrides
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

  if (punch.punchTime.isNotEmpty) {
    final checkIn = DateTime.tryParse(punch.punchTime.first);
    final checkOut = punch.punchTime.length > 1
        ? DateTime.tryParse(punch.punchTime.last)
        : null;

    /// ❌ No check-in
    if (checkIn == null) return "Absent";

    /// 🕘 Define office rules
    final officeStart = DateTime(
      checkIn.year,
      checkIn.month,
      checkIn.day,
      9,
      30,
    );

    final officeEnd = DateTime(
      checkIn.year,
      checkIn.month,
      checkIn.day,
      18,
      30,
    );

    /// ⏳ Late Entry
    if (checkIn.isAfter(officeStart)) {
      return "Late";
    }

    /// ⏳ Early Exit
    if (checkOut != null && checkOut.isBefore(officeEnd)) {
      return "EarlyExit";
    }

    /// ⏳ Work Hours Calculation
    if (checkOut != null) {
      final workedMinutes = checkOut.difference(checkIn).inMinutes;

      if (workedMinutes >= 480) return "Present"; // 8 hrs
      if (workedMinutes >= 240) return "HalfDay"; // 4 hrs
      return "LessHours";
    }

    /// ⏳ Still working
    return "InProgress";
  }

  /// ❌ Default fallback
  return "Absent";
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

class _AttendanceState extends State<Attendance>
    with SingleTickerProviderStateMixin {
  late Future aHandler;
  UserDataModel? user;
  // bool _searchApplied = false;
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
  late Map<String, EmployeeModel> employeeMap;

  late TabController tabController;

  bool isToday0(AttendanceModel a) {
    if (a.punchList.isEmpty) return false;

    final date = _parseDate(a.punchList.first.punchDate);
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

        final punch = a.punchList.first;
        final status = getAttendanceStatus(punch);

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

  @override
  void initState() {
    super.initState();
    aHandler = init();
    tabController = TabController(length: 2, vsync: this);
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

    aList.clear();
    tempAList.clear();

    aList = stats!.attendanceData;
    tempAList.addAll(aList);

    filteredList = List.from(aList);
    stats = calculateStats(filteredList);

    aList.sort((a, b) {
      if (a.punchList.isEmpty || b.punchList.isEmpty) return 0;

      final dateA = _parseDate(a.punchList.first.punchDate);
      final dateB = _parseDate(b.punchList.first.punchDate);

      if (dateA == null || dateB == null) return 0;

      return dateB.compareTo(dateA);
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
        final d1 = _parseDate(a.punchList.first.punchDate) ?? DateTime.now();
        final d2 = _parseDate(b.punchList.first.punchDate) ?? DateTime.now();
        return asc ? d1.compareTo(d2) : d2.compareTo(d1);
      });
    });
  }

  void sortByStatus(bool asc) {
    setState(() {
      filteredList.sort((a, b) {
        final s1 = getAttendanceStatus(a.punchList.first);
        final s2 = getAttendanceStatus(b.punchList.first);
        return asc ? s1.compareTo(s2) : s2.compareTo(s1);
      });
    });
  }

  void showAttendanceDetails(AttendanceModel a) {
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
      final status = getAttendanceStatus(punch);
      final type = punch.permissionType?.name ?? "";

      /// ✅ EMPLOYEE FILTER
      bool matchesEmployee = selectedEmployee == "All"
          ? true
          : a.employeeId == selectedEmployee;

      /// ✅ DEPARTMENT FILTER
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

      /// ✅ STATUS FILTER
      bool matchesStatus = selectedStatus == "All"
          ? true
          : status.toLowerCase() == selectedStatus.toLowerCase();

      /// ✅ TYPE FILTER
      bool matchesType = selectedType == "All" ? true : type == selectedType;

      /// ✅ DATE FILTER
      bool matchesDate = true;

      if (selectedDateRange != null) {
        final punchDate = _parseDate(punch.punchDate);
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
      if (a.punchList.isEmpty) continue;

      final status = getAttendanceStatus(a.punchList.first);

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

      final parsedDate = _parseDate(e.punchList.first.punchDate);
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
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: filterPanel(),
        ),

        Expanded(
          child: Column(
            children: [
              permissionApprovalPanel(),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: buildSummaryCards(stats!),
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
                    /// 📅 CALENDAR VIEW
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

                    attendanceTableView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildEmployeeView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              todaySummary(),
              const SizedBox(height: 10),
              buildSummaryCards(stats!),
            ],
          ),
        ),

        /// 🔹 TABS
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
              /// 📅 Calendar View
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _AttendanceCalendar(
                      attendanceList: filteredList,
                      userType: user!.userType,
                      employeeId: user!.uid,
                      employees: employees,
                      departments: departments,
                      onDayTap: onDayTap,
                    ),
                  ],
                ),
              ),

              /// 📋 List View
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

                          aHandler = init();
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
            /// ICON
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                /// 👤 EMPLOYEE DROPDOWN
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedEmployee,
                    decoration: const InputDecoration(
                      labelText: "Employee",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: "All", child: Text("All")),
                      ...employees.map(
                        (e) =>
                            DropdownMenuItem(value: e.uid, child: Text(e.name)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedEmployee = val!;
                        applyFilters();
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: "Department",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: "All", child: Text("All")),
                      ...departments.map(
                        (d) =>
                            DropdownMenuItem(value: d.uid, child: Text(d.name)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedDepartment = val!;
                        applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            buildFilterChips(),

            OutlinedButton.icon(
              icon: const Icon(Iconsax.calendar),
              label: Text(dateRangeText),
              onPressed: () async {
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
              },
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedEmployee = "All";
                  selectedDepartment = "All";
                  selectedStatus = "All";
                  selectedDateRange = null;
                  dateRangeText = "Select Date Range";
                  applyFilters();
                });
              },
              child: const Text("Reset"),
            ),
          ],
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
      runSpacing: 6,
      children: filters.map((f) {
        final isSelected = selectedStatus == f;

        return ChoiceChip(
          label: Text(f),
          selected: isSelected,
          selectedColor: statusColor(f).withOpacity(0.2),
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

        final status = getAttendanceStatus(punch);
        final color = statusColor(status);
        final date = _parseDate(punch.punchDate);

        final isToday =
            date != null &&
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

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
                    /// 🔷 EMPLOYEE HEADER
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

                    /// 🔷 DATE + TIME
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

                        /// EMPLOYEE VIEW STATUS
                        if (!isAdmin) buildStatusChip(status),
                      ],
                    ),

                    /// 🔷 WORK SUMMARY
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

                    /// 🔷 PERMISSION
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
      return const Center(child: Text("No Attendance Data"));
    }

    return Column(
      children: [
        /// 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: "Search Employee...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() {
                filteredList = tempAList.where((a) {
                  final emp = findEmployee(a.employeeId);
                  return emp?.name.toLowerCase().contains(
                        value.toLowerCase(),
                      ) ??
                      false;
                }).toList();
              });
            },
          ),
        ),

        /// 📊 TABLE
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              dataRowHeight: 60,
              headingRowHeight: 50,
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),

              columns: [
                DataColumn(
                  label: const Text("Employee"),
                  onSort: (i, asc) => sortByName(asc),
                ),
                DataColumn(
                  label: const Text("Date"),
                  onSort: (i, asc) => sortByDate(asc),
                ),
                const DataColumn(label: Text("Check In")),
                const DataColumn(label: Text("Check Out")),
                const DataColumn(label: Text("Work")),
                DataColumn(
                  label: const Text("Status"),
                  onSort: (i, asc) => sortByStatus(asc),
                ),
                const DataColumn(label: Text("Action")),
              ],

              rows: filteredList.map((a) {
                final emp = findEmployee(a.employeeId);
                final punch = a.punchList.first;

                final status = getAttendanceStatus(punch);
                final color = statusColor(status);
                final date = _parseDate(punch.punchDate);

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

                return DataRow(
                  cells: [
                    /// 👤 EMPLOYEE
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: color.withOpacity(.2),
                            child: Text(
                              emp?.name.substring(0, 1).toUpperCase() ?? "?",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(emp?.name ?? "Unknown"),
                        ],
                      ),
                    ),

                    /// 📅 DATE
                    DataCell(
                      Text(
                        date != null
                            ? DateFormat('dd MMM yyyy').format(date)
                            : "--",
                      ),
                    ),

                    /// ⏱ TIME
                    DataCell(Text(checkIn)),
                    DataCell(Text(checkOut)),

                    /// ⏳ WORK
                    DataCell(Text(a.formattedWork)),

                    /// 📊 STATUS
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    /// ⚡ ACTION
                    DataCell(
                      Row(
                        children: [
                          if (punch.permissionStatus ==
                              PermissionsStatus.pending) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.check,
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
                              icon: const Icon(Icons.close, color: Colors.red),
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
              }).toList(),
            ),
          ),
        ),
      ],
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
      today = filteredList.firstWhere((a) => isToday0(a));
    } catch (_) {
      today = null;
    }

    if (today == null || today.punchList.isEmpty) {
      return const SizedBox();
    }

    final punch = today.punchList.first;
    final status = getAttendanceStatus(punch);
    final color = statusColor(status);

    String formatTime(String? time) {
      if (time == null || time.isEmpty) return "--";
      final dt = DateTime.tryParse(time);
      if (dt == null) return "--";
      return TimeOfDay.fromDateTime(dt).format(context);
    }

    final hasCheckIn = punch.punchTime.isNotEmpty;
    final hasCheckOut = punch.punchTime.length > 1;

    final checkIn = hasCheckIn ? formatTime(punch.punchTime.first) : "--";

    final checkOut = hasCheckOut
        ? formatTime(punch.punchTime.last)
        : (hasCheckIn ? "Working..." : "--");

    double getProgress() {
      if (!hasCheckIn) return 0;

      final start = DateTime.tryParse(punch.punchTime.first);
      if (start == null) return 0;

      final end = hasCheckOut
          ? DateTime.tryParse(punch.punchTime.last) ?? DateTime.now()
          : DateTime.now();

      final minutes = end.difference(start).inMinutes;

      return (minutes / 480).clamp(0, 1); // 8 hrs = 480 mins
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
                /// ICON
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(getSummaryIcon(status), color: color),
                ),

                const SizedBox(width: 12),

                /// TITLE + STATUS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Attendance",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),

                      /// STATUS BADGE
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

                /// WORK TIME
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

        /// 👤 NAME + DEPARTMENT
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

  bool isWeekend(DateTime day) {
    return day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
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
                                    // fontSize: isSelected ? 16 : 14,
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
                                  // _buildDetailRow("OT", attendance.formattedOT),
                                  // _buildDetailRow(
                                  //   "Less",
                                  //   attendance.formattedLess,
                                  // ),
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
                                      /// Handle bar
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

                                      /// Date Title
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

                                      /// Status Card
                                      _infoCard(
                                        title: "Status",
                                        value: status,
                                        icon: Icons.info,
                                        color: _statusColor(status),
                                      ),

                                      const SizedBox(height: 10),

                                      /// Attendance Details
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

                                      // _infoCard(
                                      //   title: "OT Hours",
                                      //   value: attendance.formattedOT,
                                      //   icon: Icons.trending_up,
                                      // ),

                                      // _infoCard(
                                      //   title: "Less Hours",
                                      //   value: attendance.formattedLess,
                                      //   icon: Icons.trending_down,
                                      // ),
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
