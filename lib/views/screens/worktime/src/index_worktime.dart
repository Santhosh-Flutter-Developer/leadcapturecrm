// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/constants/src/svg.dart';
import 'package:leadcapture/models/models.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/firebase/src/worktime_service.dart';
import 'package:leadcapture/services/services.dart';
import 'package:leadcapture/utils/src/route.dart';
import 'package:leadcapture/views/screens/worktime/src/index_worktime_detail.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

// Project imports:
import '/theme/theme.dart';
import '/utils/utils.dart';

class DashboardWorktime extends StatefulWidget {
  const DashboardWorktime({super.key});

  @override
  State<DashboardWorktime> createState() => _DashboardWorktimeState();
}

const String _pageTitle = "Worktime";

class _DashboardWorktimeState extends State<DashboardWorktime>
    with TickerProviderStateMixin {
  late Future _workTimeHandler;
  List<WorktimeModel> _wList = [];
  final List<List<WorktimeModel>> _groupList = [];
  List<EmployeeModel> _uList = [];
  List<EmployeeModel> _nonEnrollList = [];
  int _index = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _workTimeHandler = _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<bool> _wExpanded = [];

  _init() async {
    _wList.clear();
    _uList.clear();
    _nonEnrollList.clear();
    _wExpanded.clear();
    _groupList.clear();

    _wList = await WorktimeService.dashboardWorktimeListing(
      date: DateTime.now(),
    );
    _uList = await EmployeeService.getAllEmployees();
    final worktimeUids = _wList.map((e) => e.userUid).toSet();
    _nonEnrollList = _uList
        .where((staff) => !worktimeUids.contains(staff.uid))
        .toList();

    Map<String, List<WorktimeModel>> groupedMap = {};
    for (var ride in _wList) {
      if (!groupedMap.containsKey(ride.userUid)) {
        groupedMap[ride.userUid] = [];
      }
      groupedMap[ride.userUid]!.add(ride);
    }

    _groupList.addAll(
      groupedMap.values.map((list) {
        list.sort((a, b) => b.created.compareTo(a.created));
        return list;
      }),
    );

    for (var i = 0; i < _groupList.length; i++) {
      _wExpanded.add(false);
    }

    _controller.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: FutureBuilder(
          future: _workTimeHandler,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Date Header
                    _buildDateHeader(),
                    const SizedBox(height: 24),

                    // Tab Buttons
                    _buildTabButtons(),
                    const SizedBox(height: 24),

                    // Content
                    if (_index == 1)
                      _buildActiveWorkers()
                    else
                      _buildInactiveWorkers(),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Today's Worktime Report",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                onTap: () {
                  setState(() => _index = 1);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _index == 1
                              ? AppColors.greenColor.withOpacity(0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.string(
                          clockNormalGreen,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            _index == 1 ? AppColors.greenColor : Colors.grey,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Active (${_groupList.length})",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _index == 1
                              ? AppColors.greenColor
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                onTap: () {
                  setState(() => _index = 2);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _index == 2
                              ? AppColors.redColor.withOpacity(0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.string(
                          clockAlertRed,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            _index == 2 ? AppColors.redColor : Colors.grey,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Inactive (${_nonEnrollList.length})",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _index == 2 ? AppColors.redColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkers() {
    if (_groupList.isEmpty) {
      return _buildEmptyState("No active workers today", Icons.work_off);
    }

    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      itemCount: _groupList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = _groupList[index];
        final isExpanded = _wExpanded[index];

        return Card(
          elevation: isExpanded ? 8 : 2,
          shadowColor: AppColors.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              child: Text(
                group.first.userName.isNotEmpty
                    ? group.first.userName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            title: Text(
              group.first.userName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${calculateTotalHours(group.first)} hrs",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.greenColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "View Details",
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => route(
                    context,
                    DashboardWorktimeDetail(userId: group.first.userUid),
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.only(
              left: 20,
              right: 16,
              bottom: 16,
            ),
            expandedAlignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            children: [_buildWorktimeTable(group, index)],
            onExpansionChanged: (expanded) {
              _wExpanded[index] = expanded;
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildWorktimeTable(List<WorktimeModel> group, int groupIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _buildShiftColumn("Morning", group[0])),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            if (group.length > 1)
              Expanded(child: _buildShiftColumn("Evening", group[1]))
            else
              Expanded(child: _buildEmptyShiftColumn()),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftColumn(String title, WorktimeModel shift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildTimeRow("In", shift.clockIn.formatTime),
        _buildTimeRow("Break", "${calculateBreaks(shift.breaks)}h"),
        _buildTimeRow(
          "Out",
          shift.clockOut?.formatTime ?? "--",
          shift.clockOut == null ? Colors.red : null,
        ),
      ],
    );
  }

  Widget _buildEmptyShiftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.schedule, color: Colors.grey.shade400, size: 32),
        Text(
          "No Evening Shift",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveWorkers() {
    if (_nonEnrollList.isEmpty) {
      return _buildEmptyState("All staff are active!", Icons.celebration);
    }

    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      itemCount: _nonEnrollList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final staff = _nonEnrollList[index];
        return Card(
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off,
                color: Colors.red.shade400,
                size: 24,
              ),
            ),
            title: Text(
              staff.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(staff.mobileNumber),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${staff.name} is not enrolled for worktime",
                    style: TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Colors.red.shade100,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String calculateTotalHours(WorktimeModel worktime) {
    return "8.5";
  }

  Future<void> _refresh() async {
    _workTimeHandler = _init();
    setState(() {});
  }
}
