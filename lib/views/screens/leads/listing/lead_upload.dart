import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/lead_model.dart';
import 'package:leadcapture/models/src/region_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/lead_category_service.dart';
import 'package:leadcapture/services/firebase/src/lead_priority_service.dart';
import 'package:leadcapture/services/firebase/src/lead_service.dart';
import 'package:leadcapture/services/firebase/src/lead_source_service.dart';
import 'package:leadcapture/services/firebase/src/lead_status_service.dart';
import 'package:leadcapture/services/firebase/src/region_service.dart';
import 'package:leadcapture/theme/src/app_colors.dart';
import 'package:leadcapture/utils/src/download.dart';
import 'package:leadcapture/views/components/src/xlsx_csv_reader.dart';
import 'package:leadcapture/views/ui/src/flush_bar.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

class LeadUpload extends StatefulWidget {
  const LeadUpload({super.key});

  @override
  State<LeadUpload> createState() => _LeadUploadState();
}

class _LeadUploadState extends State<LeadUpload> {
  String? _fileName;
  int _fileSize = 0;
  List<List<String>> _rows = [];
  bool _loading = false;

  Future<void> _pickAndParse() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );

      if (result == null) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      final ext = file.extension?.toLowerCase();
      final path = file.path;
      if (path == null) throw Exception('Platform returned no file path.');

      final bytes = await File(path).readAsBytes();
      List<List<String>> rows = [];

      if (ext == 'csv') {
        final str = utf8.decode(bytes);
        rows = CsvReader().parse(str);
      } else if (ext == 'xlsx') {
        rows = await XlsxReader().readFromBytes(bytes);
      }

      setState(() {
        _fileName = file.name;
        _fileSize = file.size;
        _rows = rows;
      });
    } catch (e) {
      FlushBar.show(
        context,
        'Error parsing file: ${e.toString()}',
        isSuccess: false,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetFile() => setState(() {
    _fileName = null;
    _fileSize = 0;
    _rows = [];
  });

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _uploadLeadData() async {
    try {
      if (_rows.isEmpty) return;

      if (_rows.first.length < 15) {
        FlushBar.show(
          context,
          "Error: The uploaded file does not have required columns.",
          isSuccess: false,
        );
        return;
      }

      futureLoading(context);

      int uploadedCount = 0;
      int skippedCount = 0;
      final totalRows = _rows.length - 1;

      // ✅ Load once
      final currentUser = await Spdb.getUser();
      final allCountries = await RegionService.getCountries();

      for (var i = 1; i < _rows.length; i++) {
        final row = _rows[i];

        try {
          final hasRequiredFields =
              row[0].trim().isNotEmpty &&
              row[2].trim().isNotEmpty &&
              row[4].trim().isNotEmpty &&
              row[6].trim().isNotEmpty;

          if (!hasRequiredFields) {
            skippedCount++;
            continue;
          }

          RegionModel? country;
          StateModel? state;
          CityModel? city;

          if (row[9].trim().isNotEmpty) {
            country = allCountries.firstWhere(
              (c) => c.name.toLowerCase() == row[9].trim().toLowerCase(),
            );
          }

          if (row[10].trim().isNotEmpty && country != null) {
            final states = await RegionService.getStates(
              regionId: country.uid!,
            );

            state = states.firstWhere(
              (s) => s.name.toLowerCase() == row[10].trim().toLowerCase(),
            );
          }

          if (row[11].trim().isNotEmpty && state != null) {
            final cities = await RegionService.getCities(
              regionId: country!.uid!,
              stateId: state.uid!,
            );

            city = cities.firstWhere(
              (c) => c.name.toLowerCase() == row[11].trim().toLowerCase(),
            );
          }

          final source = await LeadSourceService.getByNameOrCreate(
            name: row[2].trim(),
          );

          final category = await LeadCategoryService.getByNameOrCreate(
            name: row[3].trim(),
          );

          final priority = await LeadPriorityService.getByNameOrCreate(
            name: row[4].trim(),
          );

          final status = await LeadStatusService.getByNameOrCreate(
            name: row[6].trim(),
          );

          double leadValue = double.tryParse(row[5].trim()) ?? 0;

          DateTime createdAt = DateTime.now();
          if (row[14].trim().isNotEmpty) {
            createdAt = DateFormat("dd-MM-yyyy").parse(row[14].trim());
          }

          final leadModel = LeadModel(
            leadName: row[0].trim(),
            leadEmail: row[1].trim(),
            leadSource: source,
            leadCategory: category.name,
            leadPriority: priority.name,
            leadValue: leadValue,
            leadStatus: status.name,
            companyName: row[7].trim(),
            companyMobile: row[8].trim(),
            companyCountry: country,
            companyState: state,
            companyCity: city,
            companyAddress: row[12].trim(),
            notes: row[13].trim(),
            createdAt: createdAt,
            updatedAt: DateTime.now(),
            createdBy: currentUser,
            attachments: [],
            workflow: [],
            leadsConverted: false,
          );

          await LeadService.createLead(lead: leadModel);

          uploadedCount++;
        } catch (e, st) {
          skippedCount++;
          debugPrint("Error uploading row ${i + 1}: $e\n$st");
        }
      }

      if (Navigator.canPop(context)) Navigator.pop(context);
      Navigator.pop(context, true);

      FlushBar.show(
        context,
        "Upload Completed\n"
        "Total: $totalRows\n"
        "Uploaded: $uploadedCount\n"
        "Skipped: $skippedCount",
        isSuccess: true,
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);

      FlushBar.show(
        context,
        "Error uploading leads: ${e.toString()}",
        isSuccess: false,
      );
    }
  }

  void _showTemplateMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Menu',
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              right: 16,
              top: kIsWeb ? 60 : 100,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation.drive(Tween(begin: 0.9, end: 1.0)),
                  child: const _LeadCustomMenuCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackgroundColor,
        appBar: AppBar(
          // leading: IconButton(
          //   icon: const Icon(Iconsax.close_circle, color: AppColors.text),
          //   onPressed: () => Navigator.of(context).pop(),
          // ),
          backgroundColor: AppColors.white,
          title: Text(
            'Import Leads',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.more, color: AppColors.textLight),
              onPressed: () => _showTemplateMenu(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Upload Lead Spreadsheet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ensure your file contains Lead Name, Mobile, and Source as minimum requirements.',
                  ),
                  const SizedBox(height: 32),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _fileName == null
                        ? _buildUploadZone()
                        : _buildFileInfoCard(),
                  ),

                  if (_rows.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildPreviewHeader(),
                    const SizedBox(height: 16),
                    _buildPreviewTable(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _loading ? null : _pickAndParse,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const CircularProgressIndicator()
            else
              const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            const SizedBox(height: 16),
            const Text(
              "Click to select Lead Excel or CSV",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.success, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_formatFileSize(_fileSize)),
              ],
            ),
          ),
          IconButton(onPressed: _resetFile, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Preview",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "Showing first 10 rows of ${_rows.length - 1} leads found",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _resetFile,
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: AppColors.danger,
          ),
          label: const Text("Clear", style: TextStyle(color: AppColors.danger)),
        ),
      ],
    );
  }

  Widget _buildPreviewTable() {
    final headers = _rows.first;
    final body = _rows.skip(1).take(10).toList(); // Preview only first 10
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: body
            .map(
              (r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList()),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _uploadLeadData,
        icon: const Icon(Icons.check),
        label: const Text("Complete Import"),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _LeadCustomMenuCard extends StatelessWidget {
  const _LeadCustomMenuCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: 200, // Slightly wider for lead labels
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grey900,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              context,
              icon: Icons.file_download_outlined,
              iconColor: AppColors.success,
              label: "Lead Template",
              onTap: () async {
                await Download.downloadFromUrl(
                  context,
                  "https://firebasestorage.googleapis.com/v0/b/srisoftwarez-crm.firebasestorage.app/o/static%2Faaatp_lead_upload_template.xlsx?alt=media&token=8173a050-72a3-403e-bc10-e8c876118721",
                  "Lead Template.xlsx",
                );
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            _menuItem(
              context,
              icon: Icons.contact_page_outlined,
              iconColor: AppColors.blue,
              label: "Sample Lead Data",
              onTap: () async {
                await Download.downloadFromUrl(
                  context,
                  "https://firebasestorage.googleapis.com/v0/b/srisoftwarez-crm.firebasestorage.app/o/static%2Faaatp_lead_upload_template_with_data.xlsx?alt=media&token=831a10a4-1e61-48ec-b85e-a6fb7e964053",
                  "Lead Template.xlsx",
                );
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
