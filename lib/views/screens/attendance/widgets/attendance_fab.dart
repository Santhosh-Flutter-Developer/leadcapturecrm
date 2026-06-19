import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/attendance_model.dart';
import 'package:leadcapture/models/src/employee_model.dart';
import 'package:leadcapture/models/src/filter_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';
import 'package:leadcapture/services/firebase/src/employee_service.dart';
import 'package:leadcapture/theme/src/app_colors.dart';
import 'package:leadcapture/views/ui/src/flush_bar.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

class AttendanceFAB extends StatefulWidget {
  const AttendanceFAB({super.key});

  @override
  State<AttendanceFAB> createState() => _AttendanceFABState();
}

class _AttendanceFABState extends State<AttendanceFAB> {
  EmployeeModel? employee;
  List<PunchModel> todayPunches = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = await Spdb.getUid();
    if (uid != null) {
      employee = await EmployeeService.getEmployee(uid: uid);
      await _loadTodayPunches();
    }
  }

  Future<void> _loadTodayPunches() async {
    if (employee == null) return;
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final attendance = await AttendanceService.getAttendance(
        filter: FilterModel(
          pageNumber: 1,
          fromDate: todayStart,
          toDate: todayEnd,
          pageLimit: 100,
        ),
      );

      if (mounted) {
        setState(() {
          todayPunches = attendance.punchList;
        });
      }
    } catch (e) {
      debugPrint('Error loading today punches: $e');
    }
  }

  Future<void> _showPunchSelectorSheet() async {
    await _loadTodayPunches();
    if (!mounted) return;

    final inPunches = todayPunches
        .where((p) => p.clockIn != null && p.clockOut == null)
        .toList();
    final outPunches = todayPunches.where((p) => p.clockOut != null).toList();

    final bool mustBeOut = inPunches.length > outPunches.length;
    final bool mustBeIn = inPunches.length == outPunches.length;

    String selectedType = mustBeOut ? 'out' : 'in';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => _PunchSelectorSheet(
        employeeName: employee?.name ?? 'Employee',
        todayPunches: todayPunches,
        inPunches: inPunches,
        outPunches: outPunches,
        mustBeOut: mustBeOut,
        mustBeIn: mustBeIn,
        preSelectedType: selectedType,
        onConfirm: (type) async {
          Navigator.of(ctx).pop();
          await _savePunch(type);
        },
        onCancel: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _savePunch(String punchType) async {
    try {
      futureLoading(context);

      if (punchType == 'in') {
        await AttendanceService.createPunch(
          userUid: employee!.uid!,
          workingMinutes: 0,
          otMinutes: 0,
          lessMinutes: 0,
          status: 'present',
        );
      } else {
        final latestPunch = todayPunches.where((p) => p.clockOut == null).first;
        if (latestPunch.uid != null) {
          await AttendanceService.clockOut(latestPunch.uid!);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        final label = punchType == 'in' ? 'Punch IN' : 'Punch OUT';
        FlushBar.show(context, '$label recorded successfully', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        FlushBar.show(context, 'Failed to record punch: $e', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _showPunchSelectorSheet,
      backgroundColor: AppColors.primaryColor,
      icon: const Icon(Icons.login, color: Colors.white),
      label: const Text(
        'Mark Attendance',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PunchSelectorSheet extends StatefulWidget {
  final String employeeName;
  final List<PunchModel> todayPunches;
  final List<PunchModel> inPunches;
  final List<PunchModel> outPunches;
  final bool mustBeOut;
  final bool mustBeIn;
  final String preSelectedType;
  final Future<void> Function(String type) onConfirm;
  final VoidCallback onCancel;

  const _PunchSelectorSheet({
    required this.employeeName,
    required this.todayPunches,
    required this.inPunches,
    required this.outPunches,
    required this.mustBeOut,
    required this.mustBeIn,
    required this.preSelectedType,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_PunchSelectorSheet> createState() => _PunchSelectorSheetState();
}

class _PunchSelectorSheetState extends State<_PunchSelectorSheet> {
  late String selectedType;
  String? validationError;

  @override
  void initState() {
    super.initState();
    selectedType = widget.preSelectedType;
    _validate(selectedType);
  }

  void _validate(String type) {
    String? err;
    if (type == 'out' && widget.inPunches.length <= widget.outPunches.length) {
      err = 'You must Punch IN before punching OUT.';
    } else if (type == 'in' &&
        widget.inPunches.length > widget.outPunches.length) {
      err = 'You must Punch OUT before punching IN again.';
    }
    setState(() => validationError = err);
  }

  void _select(String type) {
    setState(() => selectedType = type);
    _validate(type);
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _totalHours() {
    int totalMins = 0;
    final pairs = widget.inPunches.length < widget.outPunches.length
        ? widget.inPunches.length
        : widget.outPunches.length;
    for (int i = 0; i < pairs; i++) {
      if (widget.inPunches[i].clockIn != null &&
          widget.outPunches[i].clockOut != null) {
        final diff = widget.outPunches[i].clockOutDate!
            .difference(widget.inPunches[i].clockInDate!)
            .inMinutes;
        if (diff > 0) totalMins += diff;
      }
    }
    if (totalMins == 0) return '0h 0m';
    return '${totalMins ~/ 60}h ${totalMins % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.login_rounded,
                      color: AppColors.primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark Attendance',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.employeeName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current time chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          nowStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 20),

            // Today's Punch History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text(
                        "Today's Punch History",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (widget.todayPunches.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Total: ${_totalHours()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.todayPunches.isEmpty)
                    const Text(
                      'No punches recorded today',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    )
                  else
                    ...widget.todayPunches.map((punch) {
                      final clockInTime = punch.clockInDate != null
                          ? _fmt(punch.clockInDate!)
                          : '-';
                      final clockOutTime = punch.clockOutDate != null
                          ? _fmt(punch.clockOutDate!)
                          : '-';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: punch.clockOut != null
                                    ? Colors.green
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              clockInTime,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Text(' - ', style: TextStyle(fontSize: 13)),
                            Text(
                              clockOutTime,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 20),

            // Punch Type Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Punch Type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _select('in'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'in'
                                  ? AppColors.primaryColor
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == 'in'
                                    ? AppColors.primaryColor
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  color: selectedType == 'in'
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Punch IN',
                                  style: TextStyle(
                                    color: selectedType == 'in'
                                        ? Colors.white
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _select('out'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedType == 'out'
                                  ? AppColors.primaryColor
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == 'out'
                                    ? AppColors.primaryColor
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: selectedType == 'out'
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Punch OUT',
                                  style: TextStyle(
                                    color: selectedType == 'out'
                                        ? Colors.white
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (validationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationError!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: validationError == null
                          ? () => widget.onConfirm(selectedType)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: const Text('Confirm'),
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
}
