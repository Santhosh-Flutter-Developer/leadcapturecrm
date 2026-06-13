import 'package:flutter/material.dart';
import '/theme/theme.dart';

class SummaryStrip extends StatelessWidget {
  final int totalRecords;
  final int totalMinutes;
  final int presentDays;
  final int absentDays;

  const SummaryStrip({
    super.key,
    required this.totalRecords,
    required this.totalMinutes,
    required this.presentDays,
    required this.absentDays,
  });

  String _formatHours(int minutes) {
    if (minutes <= 0) return '-';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _formatAvgHours(int minutes, int days) {
    if (days == 0) return '-';
    final avg = minutes ~/ days;
    return _formatHours(avg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.white,
      child: Row(
        children: [
          _buildStatCard(
            'Records',
            '$totalRecords',
            AppColors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Total Hours',
            _formatHours(totalMinutes),
            AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Present',
            '$presentDays',
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Absent',
            '$absentDays',
            AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'GoogleSans',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
                fontFamily: 'GoogleSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
