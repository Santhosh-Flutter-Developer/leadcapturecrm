import 'package:flutter/material.dart';
import '/theme/theme.dart';

class DateRangeStrip extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const DateRangeStrip({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onTap,
    required this.onReset,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _dayRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) return '';
    final days = to.difference(from).inDays + 1;
    return '$days day${days != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: AppColors.primary.withOpacity(0.04),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              '${_formatDate(fromDate)} – ${_formatDate(toDate)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'GoogleSans',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _dayRange(fromDate, toDate),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                foregroundColor: AppColors.grey600,
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontFamily: 'GoogleSans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
