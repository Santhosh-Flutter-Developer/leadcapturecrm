import 'package:flutter/material.dart';
import '/theme/theme.dart';

enum ExportFormat { pdf, excel }

class ExportFormatDialog extends StatelessWidget {
  const ExportFormatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Export Format',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.grey900,
          fontFamily: 'GoogleSans',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFormatOption(
            context,
            icon: Icons.picture_as_pdf,
            label: 'PDF',
            description: 'Export as PDF document',
            format: ExportFormat.pdf,
          ),
          const SizedBox(height: 12),
          _buildFormatOption(
            context,
            icon: Icons.table_chart,
            label: 'Excel',
            description: 'Export as Excel spreadsheet',
            format: ExportFormat.excel,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.grey600,
              fontFamily: 'GoogleSans',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required ExportFormat format,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
