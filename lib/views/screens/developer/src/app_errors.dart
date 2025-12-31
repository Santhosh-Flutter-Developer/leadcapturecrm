import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '/views/views.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';

class DevColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
}

class AppErrors extends StatefulWidget {
  const AppErrors({super.key});

  @override
  State<AppErrors> createState() => _AppErrorsState();
}

class _AppErrorsState extends State<AppErrors> {
  FirebaseFirestore firebase = FirebaseFirestore.instance;
  bool _loading = false;
  List<Map<String, dynamic>> _errors = [];
  Map<String, dynamic>? _selectedError;

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  Future<void> _loadErrors() async {
    setState(() => _loading = true);
    try {
      final query = await firebase
          .collection(Collections.errors.name)
          .orderBy("time", descending: true)
          .limit(100)
          .get();

      final List<Map<String, dynamic>> list = [];
      for (var doc in query.docs) {
        final data = doc.data();
        list.add({
          "id": doc.id,
          "cid": data["cid"],
          "uid": data["uid"],
          "error": data["error"],
          "stackTrace": data["stackTrace"],
          "device": data["device"],
          "time": data["time"] is Timestamp
              ? (data["time"] as Timestamp).toDate()
              : null,
        });
      }
      setState(() {
        _errors = list;
        _loading = false;
        // Auto-select first error on desktop if available
        if (_errors.isNotEmpty && _selectedError == null) {
          _selectedError = _errors.first;
        }
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        FlushBar.show(context, 'Error loading logs', isSuccess: false);
      }
    }
  }

  String _formatTime(DateTime? t) {
    if (t == null) return "-";
    return DateFormat("dd MMM, hh:mm a").format(t);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    FlushBar.show(context, 'Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.white,
        elevation: 0,
        centerTitle: false,
        leading: const Back(color: AppColors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Logs",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: DevColors.textPrimary,
                fontSize: 18,
              ),
            ),
            Text(
              "Latest 100 entries",
              style: TextStyle(
                fontSize: 11,
                color: DevColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Iconsax.refresh,
              color: DevColors.primary,
              size: 20,
            ),
            onPressed: _loadErrors,
            tooltip: "Reload",
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: DevColors.border, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: WaitingLoading())
          : _errors.isEmpty
          ? _buildEmptyState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 1100;
                return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
              },
            ),
    );
  }

  /// DESKTOP LAYOUT: Master-Detail Split Pane
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side: Error Feed
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: DevColors.white,
            border: Border(right: BorderSide(color: DevColors.border)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _errors.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = _errors[index];
              final isSelected = _selectedError?["id"] == item["id"];
              return ListTile(
                selected: isSelected,
                selectedTileColor: DevColors.primary.withValues(alpha: 0.05),
                onTap: () => setState(() => _selectedError = item),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(
                  item["error"] ?? "Unknown Exception",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                    color: isSelected
                        ? DevColors.primary
                        : DevColors.textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(item["time"]),
                    style: const TextStyle(
                      fontSize: 11,
                      color: DevColors.textSecondary,
                    ),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Iconsax.arrow_right_3,
                        size: 14,
                        color: DevColors.primary,
                      )
                    : null,
              );
            },
          ),
        ),
        // Right Side: Detailed View
        Expanded(
          child: _selectedError == null
              ? const Center(child: Text("Select a log to view details"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildLogDetails(_selectedError!),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// MOBILE LAYOUT: Traditional Expansion List
  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _errors.length,
      itemBuilder: (context, index) => _buildErrorCard(_errors[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.tick_circle, size: 48, color: DevColors.border),
          const SizedBox(height: 16),
          const Text(
            "No system errors detected",
            style: TextStyle(
              color: DevColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> errorData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DevColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: DevColors.textSecondary,
          collapsedIconColor: DevColors.textSecondary,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DevColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "ERROR",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: DevColors.danger,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorData["error"] ?? "Unknown Exception",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: DevColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(errorData["time"]),
              style: const TextStyle(
                fontSize: 12,
                color: DevColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Container(
              color: DevColors.border.withValues(alpha: 0.5),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildLogDetails(errorData),
            ),
          ],
        ),
      ),
    );
  }

  /// REUSABLE COMPONENT: Detailed log content
  Widget _buildLogDetails(Map<String, dynamic> errorData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSection("EXCEPTION", errorData["error"], copy: true),
        const SizedBox(height: 16),
        _buildDetailSection(
          "STACK TRACE",
          errorData["stackTrace"],
          copy: true,
          isCode: true,
        ),
        const SizedBox(height: 24),
        const Text(
          "METADATA",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: DevColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DevColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DevColors.border),
          ),
          child: Column(
            children: [
              _buildMetadataRow("Collection ID", errorData["cid"]),
              const Divider(height: 20, thickness: 0.5),
              _buildMetadataRow("User ID", errorData["uid"]),
              const Divider(height: 20, thickness: 0.5),
              _buildMetadataRow("Device info", errorData["device"]?.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(
    String label,
    String? value, {
    bool copy = false,
    bool isCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: DevColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            if (copy && value != null)
              InkWell(
                onTap: () => _copy(value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.copy, size: 12, color: DevColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        "Copy",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: DevColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCode ? const Color(0xFF0F172A) : DevColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DevColors.border),
          ),
          child: SelectableText(
            value ?? "-",
            style: TextStyle(
              fontSize: 12,
              color: isCode ? const Color(0xFFF1F5F9) : DevColors.textPrimary,
              fontFamily: isCode ? 'monospace' : null,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String? value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DevColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: SelectableText(
            value ?? "-",
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: DevColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
