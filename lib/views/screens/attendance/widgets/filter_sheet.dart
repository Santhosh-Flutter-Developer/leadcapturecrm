import 'package:flutter/material.dart';
import '/theme/theme.dart';

class FilterSheet extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialEmployeeId;
  final String? initialDepartmentId;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> departments;
  final Function({
    DateTime? from,
    DateTime? to,
    String? employeeId,
    String? departmentId,
    String? preset,
  }) onApply;

  const FilterSheet({
    super.key,
    required this.initialFromDate,
    required this.initialToDate,
    required this.initialEmployeeId,
    required this.initialDepartmentId,
    required this.employees,
    required this.departments,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTime? fromDate;
  late DateTime? toDate;
  late String? employeeId;
  late String? departmentId;
  String? selectedPreset;

  @override
  void initState() {
    super.initState();
    fromDate = widget.initialFromDate;
    toDate = widget.initialToDate;
    employeeId = widget.initialEmployeeId;
    departmentId = widget.initialDepartmentId;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (isFrom ? fromDate : toDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) {
      setState(() {
        if (isFrom) {
          fromDate = d;
        } else {
          toDate = d;
        }
        selectedPreset = null;
      });
    }
  }

  void _quickSelect(String preset) {
    final now = DateTime.now();
    setState(() {
      selectedPreset = preset;
      switch (preset) {
        case 'today':
          fromDate = now;
          toDate = now;
          break;
        case 'week':
          fromDate = now.subtract(Duration(days: now.weekday - 1));
          toDate = now;
          break;
        case 'month':
          fromDate = DateTime(now.year, now.month, 1);
          toDate = now;
          break;
        case 'last_month':
          fromDate = DateTime(now.year, now.month - 1, 1);
          toDate = DateTime(now.year, now.month, 0);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                    fontFamily: 'GoogleSans',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.grey600,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Select Chips
            Text(
              'Quick Select',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
                fontFamily: 'GoogleSans',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('Today', 'today'),
                _buildPresetChip('This Week', 'week'),
                _buildPresetChip('This Month', 'month'),
                _buildPresetChip('Last Month', 'last_month'),
              ],
            ),
            const SizedBox(height: 20),

            // Date Range
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
                fontFamily: 'GoogleSans',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateField('From', fromDate, () => _pickDate(true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField('To', toDate, () => _pickDate(false)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Employee Filter
            if (widget.employees.isNotEmpty) ...[
              Text(
                'Employee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                  fontFamily: 'GoogleSans',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: employeeId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Employees'),
                  ),
                  ...widget.employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp['id'] as String?,
                      child: Text(emp['name'] as String? ?? ''),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => employeeId = value);
                },
              ),
              const SizedBox(height: 20),
            ],

            // Department Filter
            if (widget.departments.isNotEmpty) ...[
              Text(
                'Department',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                  fontFamily: 'GoogleSans',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: departmentId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...widget.departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept['id'] as String?,
                      child: Text(dept['name'] as String? ?? ''),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => departmentId = value);
                },
              ),
              const SizedBox(height: 20),
            ],

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    from: fromDate,
                    to: toDate,
                    employeeId: employeeId,
                    departmentId: departmentId,
                    preset: selectedPreset,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'GoogleSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String preset) {
    final isSelected = selectedPreset == preset;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _quickSelect(preset),
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.grey600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontFamily: 'GoogleSans',
      ),
      backgroundColor: AppColors.grey100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: AppColors.grey600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 14,
                  color: date != null ? AppColors.grey900 : AppColors.grey500,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
