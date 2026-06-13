import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/enum.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/department_model.dart';
import 'package:leadcapture/models/src/employee_model.dart';
import 'package:leadcapture/models/src/holiday_model.dart';
import 'package:leadcapture/models/src/user_data_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';
import 'package:leadcapture/services/firebase/src/attendance_export_service.dart';
import 'package:leadcapture/services/firebase/src/employee_service.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/theme/theme.dart';
import 'package:leadcapture/utils/src/platform.dart';
import 'package:leadcapture/views/screens/attendance/attendance_helper.dart';
import 'package:leadcapture/views/screens/attendance/widgets/date_range_strip.dart';
import 'package:leadcapture/views/screens/attendance/widgets/summary_strip.dart';
import 'package:leadcapture/views/screens/attendance/widgets/filter_sheet.dart';
import 'package:leadcapture/views/screens/attendance/widgets/view_toggle_btn.dart';
import 'package:leadcapture/views/screens/attendance/widgets/export_format_dialog.dart';
import 'package:leadcapture/views/ui/src/flush_bar.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

const String _pageTitle = "Attendance";

class AttendanceEnhanced extends StatefulWidget {
  const AttendanceEnhanced({super.key});

  @override
  State<AttendanceEnhanced> createState() => _AttendanceEnhancedState();
}

class _AttendanceEnhancedState extends State<AttendanceEnhanced>
    with SingleTickerProviderStateMixin {
  late Future aHandler;
  UserDataModel? user;
  final TextEditingController _search = TextEditingController();
  String selectedStatus = "All";
  String selectedType = "All";
  DateTime? fromDate;
  DateTime? toDate;
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
  List<HolidayModel> holidays = [];

  // New features
  String viewMode = 'table'; // 'table' or 'grid'
  String activePreset = 'month';

  @override
  void initState() {
    super.initState();
    aHandler = init();
    tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });

    // Initialize date range to current month
    DateTime now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = now;
  }

  @override
  void dispose() {
    _timer?.cancel();
    tabController.dispose();
    super.dispose();
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
    DateTime initFromDate = DateTime(now.year, now.month, 1);
    DateTime initToDate = DateTime(now.year, now.month + 1, 0);

    aList.clear();

    if (isEmployee) {
      if (user?.uid == null) return;

      final res = await AttendanceService.getAttendanceStats(
        userUid: user!.uid,
        fromDate: initFromDate,
        toDate: initToDate,
        holidays: holidays,
      );

      aList.addAll(res.attendanceData);
    } else if (isAdmin) {
      final futures = employees.map((emp) {
        return AttendanceService.getAttendanceStats(
          userUid: emp.uid!,
          fromDate: initFromDate,
          toDate: initToDate,
          holidays: holidays,
        );
      }).toList();

      final results = await Future.wait(futures);

      for (var res in results) {
        aList.addAll(res.attendanceData);
      }
    }

    if (isAdmin) {
      workList = await WorktimeService.dashboardWorktimeListing(
        date: DateTime.now(),
      );
    } else {
      workList = await WorktimeService.userWorktimeListing(userId: user!.uid);
    }

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

    tempAList.clear();
    tempAList.addAll(aList);

    applyFilters();

    aList.sort((a, b) {
      if (a.punchList.isEmpty || b.punchList.isEmpty) return 0;

      final dateA = parseDateTime(a.punchList.first.punchDate);
      final dateB = parseDateTime(b.punchList.first.punchDate);

      if (dateA == null || dateB == null) return 0;

      return dateB.compareTo(dateA);
    });
  }

  void applyFilters({
    DateTime? from,
    DateTime? to,
    String? employeeId,
    String? departmentId,
    String? preset,
  }) {
    setState(() {
      if (from != null) fromDate = from;
      if (to != null) toDate = to;
      if (employeeId != null) {
        selectedEmployee = employeeId.isEmpty ? "All" : employeeId;
      }
      if (departmentId != null) {
        selectedDepartment = departmentId.isEmpty ? "All" : departmentId;
      }
      if (preset != null) activePreset = preset;

      filteredList = tempAList.where((a) {
        // Date filter
        if (fromDate != null && toDate != null) {
          if (a.punchList.isNotEmpty) {
            final date = parseDateTime(a.punchList.first.punchDate);
            if (date != null) {
              if (date.isBefore(fromDate!) || date.isAfter(toDate!)) {
                return false;
              }
            }
          }
        }

        // Employee filter
        if (selectedEmployee != "All") {
          if (a.employeeId != selectedEmployee) return false;
        }

        // Department filter
        if (selectedDepartment != "All") {
          final emp = employeeMap[a.employeeId];
          if (emp?.department != selectedDepartment) return false;
        }

        // Status filter
        if (selectedStatus != "All") {
          final status = getAttendanceStatus(a);
          if (status.toLowerCase() != selectedStatus.toLowerCase()) {
            return false;
          }
        }

        // Search filter
        if (_search.text.isNotEmpty) {
          final emp = employeeMap[a.employeeId];
          if (emp != null) {
            if (!emp.name.toLowerCase().contains(_search.text.toLowerCase())) {
              return false;
            }
          }
        }

        return true;
      }).toList();

      filteredList.sort((a, b) {
        if (a.punchList.isEmpty || b.punchList.isEmpty) return 0;

        final dateA = parseDateTime(a.punchList.first.punchDate);
        final dateB = parseDateTime(b.punchList.first.punchDate);

        if (dateA == null || dateB == null) return 0;

        return dateB.compareTo(dateA);
      });
    });
  }

  void clearFilters() {
    DateTime now = DateTime.now();
    setState(() {
      fromDate = DateTime(now.year, now.month, 1);
      toDate = now;
      selectedEmployee = "All";
      selectedDepartment = "All";
      selectedStatus = "All";
      activePreset = 'month';
      _search.clear();
    });
    applyFilters();
  }

  void showFilterSheet() {
    final employeeOptions = employees
        .map((e) => {'id': e.uid, 'name': e.name})
        .toList();
    final departmentOptions = departments
        .map((d) => {'id': d.uid, 'name': d.name})
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        initialFromDate: fromDate,
        initialToDate: toDate,
        initialEmployeeId: selectedEmployee == "All" ? null : selectedEmployee,
        initialDepartmentId: selectedDepartment == "All"
            ? null
            : selectedDepartment,
        employees: employeeOptions,
        departments: departmentOptions,
        onApply:
            ({
              DateTime? from,
              DateTime? to,
              String? employeeId,
              String? departmentId,
              String? preset,
            }) {
              applyFilters(
                from: from,
                to: to,
                employeeId: employeeId,
                departmentId: departmentId,
                preset: preset,
              );
            },
      ),
    );
  }

  Future<void> showExportMenu() async {
    if (filteredList.isEmpty) {
      FlushBar.show(context, 'No data to export', isSuccess: false);
      return;
    }

    final format = await showDialog<ExportFormat>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ExportFormatDialog(),
    );

    if (format == null || !context.mounted) return;

    try {
      if (format == ExportFormat.pdf) {
        await AttendanceExportService.exportPDF(
          context: context,
          attendanceList: filteredList,
          employeeMap: employeeMap,
          fromDate: fromDate ?? DateTime.now(),
          toDate: toDate ?? DateTime.now(),
          companyName: 'Lead Capture',
        );
      } else {
        await AttendanceExportService.exportExcel(
          context: context,
          attendanceList: filteredList,
          employeeMap: employeeMap,
          fromDate: fromDate ?? DateTime.now(),
          toDate: toDate ?? DateTime.now(),
          companyName: 'Lead Capture',
        );
      }
    } catch (e) {
      FlushBar.show(context, 'Export failed: $e', isSuccess: false);
    }
  }

  String formatTime(int? time) {
    if (time == null) return "-";
    final dt = DateTime.fromMillisecondsSinceEpoch(time);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  String formatDatetime(DateTime? time) {
    if (time == null) return "-";
    return TimeOfDay.fromDateTime(time).format(context);
  }

  EmployeeModel? findEmployee(String uid) {
    try {
      return employees.firstWhere((e) => e.uid == uid);
    } catch (_) {
      return null;
    }
  }

  int get totalRecords => filteredList.length;
  int get totalMinutes =>
      filteredList.fold(0, (sum, a) => sum + a.workingHourMinutes);
  int get presentDays =>
      filteredList.where((a) => getAttendanceStatus(a) == "Present").length;
  int get absentDays =>
      filteredList.where((a) => getAttendanceStatus(a) == "Absent").length;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(_pageTitle),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (isWide)
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  ViewToggleBtn(
                    icon: Icons.table_rows_rounded,
                    tooltip: 'Table View',
                    selected: viewMode == 'table',
                    onTap: () => setState(() => viewMode = 'table'),
                  ),
                  ViewToggleBtn(
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Grid View',
                    selected: viewMode == 'grid',
                    onTap: () => setState(() => viewMode = 'grid'),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          isWide
              ? ElevatedButton.icon(
                  onPressed: showFilterSheet,
                  icon: const Icon(Icons.filter_list_rounded, size: 18),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                )
              : IconButton(
                  onPressed: showFilterSheet,
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Filter',
                ),
          const SizedBox(width: 8),
          isWide
              ? ElevatedButton.icon(
                  onPressed: showExportMenu,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                )
              : IconButton(
                  onPressed: showExportMenu,
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Export',
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder(
        future: aHandler,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: AppColors.danger),
              ),
            );
          }

          return Column(
            children: [
              // Date Range Strip
              DateRangeStrip(
                fromDate: fromDate,
                toDate: toDate,
                onTap: showFilterSheet,
                onReset: clearFilters,
              ),

              // Summary Strip
              SummaryStrip(
                totalRecords: totalRecords,
                totalMinutes: totalMinutes,
                presentDays: presentDays,
                absentDays: absentDays,
              ),

              const Divider(height: 1, color: AppColors.grey300),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search by employee name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) => applyFilters(),
                ),
              ),

              // Mobile view toggle
              if (!isWide)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.grey300),
                        ),
                        child: Row(
                          children: [
                            ViewToggleBtn(
                              icon: Icons.table_rows_rounded,
                              tooltip: 'Table View',
                              selected: viewMode == 'table',
                              onTap: () => setState(() => viewMode = 'table'),
                            ),
                            ViewToggleBtn(
                              icon: Icons.grid_view_rounded,
                              tooltip: 'Grid View',
                              selected: viewMode == 'grid',
                              onTap: () => setState(() => viewMode = 'grid'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assessment_outlined,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.grey600,
                                fontFamily: 'GoogleSans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: showFilterSheet,
                              child: const Text('Change Filters'),
                            ),
                          ],
                        ),
                      )
                    : viewMode == 'table'
                    ? _buildTableView()
                    : _buildGridView(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final attendance = filteredList[index];
        final emp = employeeMap[attendance.employeeId];
        final punch = attendance.punchList.isNotEmpty
            ? attendance.punchList.first
            : null;
        final status = getAttendanceStatus(attendance);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.grey200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        emp?.name.isNotEmpty == true
                            ? emp!.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'GoogleSans',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp?.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                              fontFamily: 'GoogleSans',
                            ),
                          ),
                          if (punch?.punchDate != null)
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                              ).format(parseDateTime(punch!.punchDate)!),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey600,
                                fontFamily: 'GoogleSans',
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTimeInfo(
                      'Check In',
                      punch?.clockIn != null ? formatTime(punch!.clockIn) : '-',
                    ),
                    const SizedBox(width: 24),
                    _buildTimeInfo(
                      'Check Out',
                      punch?.clockOut != null
                          ? formatTime(punch!.clockOut)
                          : '-',
                    ),
                    const SizedBox(width: 24),
                    _buildTimeInfo('Work Hours', attendance.formattedWork),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final attendance = filteredList[index];
        final emp = employeeMap[attendance.employeeId];
        final punch = attendance.punchList.isNotEmpty
            ? attendance.punchList.first
            : null;
        final status = getAttendanceStatus(attendance);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.grey200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        emp?.name.isNotEmpty == true
                            ? emp!.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'GoogleSans',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        emp?.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                          fontFamily: 'GoogleSans',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (punch?.punchDate != null)
                  Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(parseDateTime(punch!.punchDate)!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                const Spacer(),
                _buildStatusChip(status),
                const SizedBox(height: 8),
                Text(
                  attendance.formattedWork,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700,
                    fontFamily: 'GoogleSans',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'present':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case 'absent':
        bgColor = AppColors.danger.withOpacity(0.1);
        textColor = AppColors.danger;
        break;
      case 'late':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case 'half day':
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        break;
      default:
        bgColor = AppColors.grey300;
        textColor = AppColors.grey600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'GoogleSans',
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.grey500,
            fontFamily: 'GoogleSans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
            fontFamily: 'GoogleSans',
          ),
        ),
      ],
    );
  }
}
