import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import 'bloc/backup_bloc.dart';

class BackupColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class BackupListing extends StatefulWidget {
  const BackupListing({super.key});

  @override
  State<BackupListing> createState() => _BackupListingState();
}

class _BackupListingState extends State<BackupListing> {
  final BackupTrigger _trigger = BackupTrigger();
  String _search = '';
  bool _busy = false;
  BackupModel? _selectedBackup;

  final Map<String, List<String>> _exampleSubcollectionsMap = {
    'users': [
      'activityLogs',
      'admins',
      'chats',
      'clients',
      'dealStatus',
      'deals',
      'departments',
      'designations',
      'employees',
      'feed',
      'leadCategory',
      'leadStatus',
      'leads',
      'loginLogs',
      'notifications',
      'projects',
      'roles',
      'settings',
      'subDepartments',
      'tasks',
      'trash',
      'version',
    ],
    'chats': ['messages'],
    'tasks': ['taskHistory', 'taskComments'],
  };

  Future<void> _refresh(BuildContext context) async {
    context.read<BackupBloc>().add(StreamBackup());
    await Future.delayed(const Duration(milliseconds: 350));
  }

  Map<String, List<BackupModel>> _groupByDay(List<BackupModel> items) {
    final Map<String, List<BackupModel>> map = {};
    final now = DateTime.now();

    for (final item in items) {
      final dt = item.timestamp;
      final diff = DateTime(
        dt.year,
        dt.month,
        dt.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;

      String label;
      if (diff == 0) {
        label = 'Today';
      } else if (diff == -1) {
        label = 'Yesterday';
      } else {
        label = DateFormat('dd MMM yyyy').format(dt);
      }

      map.putIfAbsent(label, () => []).add(item);
    }
    return map;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _avatar(String text, {double size = 48}) {
    final initial = (text.isNotEmpty)
        ? text.trim().substring(0, 1).toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BackupColors.primary,
            BackupColors.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Future<void> exportBackup(BuildContext context) async {
    final List<String> paths = ['/users/KUsgiMjuGIdmQBMhFKNJ/'];
    try {
      setState(() => _busy = true);
      final url = await _trigger.backupPaths(
        paths,
        subcollectionsMap: _exampleSubcollectionsMap,
      );
      setState(() => _busy = false);

      if (url.isNotEmpty) {
        if (!mounted) return;
        await _showResultDialog(
          context,
          'Backup Success',
          'A new data snapshot has been created and uploaded to the secure vault.',
          url: url,
        );
        context.read<BackupBloc>().add(StreamBackup());
      }
    } catch (e) {
      setState(() => _busy = false);
      FlushBar.show(context, 'Export failed: $e', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BackupBloc()..add(StreamBackup()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: const Back(color: AppColors.black),
          centerTitle: false,
          title: const Text(
            "Security Vault",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: BackupColors.textPrimary,
              fontSize: 18,
            ),
          ),
          actions: [
            if (_busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                onPressed: () => context.read<BackupBloc>().add(StreamBackup()),
                icon: const Icon(
                  Iconsax.refresh,
                  color: BackupColors.primary,
                  size: 20,
                ),
              ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: BackupColors.border, height: 1),
          ),
        ),
        body: BlocBuilder<BackupBloc, BackupState>(
          builder: (context, state) {
            if (state is BackupLoading) {
              return const Center(child: WaitingLoading());
            }
            if (state is BackupError) return _buildErrorState(state.message);
            if (state is BackupLoaded) {
              final items = state.backups.where((b) {
                if (_search.isEmpty) return true;
                final s = _search.toLowerCase();
                return b.path.toLowerCase().contains(s) ||
                    b.url.toLowerCase().contains(s);
              }).toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth > 1100;
                  return isDesktop
                      ? _buildDesktopLayout(items)
                      : _buildMobileLayout(items);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// DESKTOP LAYOUT: Master-Detail Split Pane
  Widget _buildDesktopLayout(List<BackupModel> backups) {
    final grouped = _groupByDay(backups);

    return Row(
      children: [
        // Master List
        Container(
          width: 420,
          decoration: const BoxDecoration(
            color: BackupColors.white,
            border: Border(right: BorderSide(color: BackupColors.border)),
          ),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: backups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          return _buildGroupSection(
                            entry.key,
                            entry.value,
                            isDesktop: true,
                          );
                        },
                      ),
              ),
              _buildExportBar(),
            ],
          ),
        ),
        // Detail View
        Expanded(
          child: _selectedBackup == null
              ? _buildEmptyDetailView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(60),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildDetailContent(_selectedBackup!),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// MOBILE LAYOUT: Traditional List View
  Widget _buildMobileLayout(List<BackupModel> backups) {
    final grouped = _groupByDay(backups);

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: backups.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return _buildGroupSection(
                        entry.key,
                        entry.value,
                        isDesktop: false,
                      );
                    },
                  ),
                ),
        ),
        _buildExportBar(isMobile: true),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: BackupColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BackupColors.border),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _search = v.trim()),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Iconsax.search_normal,
              size: 18,
              color: BackupColors.textSecondary,
            ),
            hintText: 'Filter registry...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: BackupColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildExportBar({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isMobile ? 32 : 12),
      decoration: const BoxDecoration(
        color: BackupColors.white,
        border: Border(top: BorderSide(color: BackupColors.border)),
      ),
      child: ElevatedButton.icon(
        onPressed: _busy ? null : () => exportBackup(context),
        icon: const Icon(Iconsax.export_3, size: 18),
        label: const Text("Create New Snapshot"),
        style: ElevatedButton.styleFrom(
          backgroundColor: BackupColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildGroupSection(
    String label,
    List<BackupModel> items, {
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: BackupColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildBackupItem(item, isDesktop)),
      ],
    );
  }

  Widget _buildBackupItem(BackupModel item, bool isDesktop) {
    final isSelected = _selectedBackup?.uid == item.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () {
          if (isDesktop) {
            setState(() => _selectedBackup = item);
          } else {
            _showMobileDetailSheet(item);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? BackupColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BackupColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              _avatar(item.type, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? BackupColors.primary
                            : BackupColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(item.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: BackupColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 14,
                  color: BackupColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BackupModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(item.type, size: 64),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.path,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: BackupColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Snapshot Type: ${item.type}",
                    style: const TextStyle(
                      color: BackupColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildDetailSection("REGISTRY DETAILS", [
          _detailRow(
            "Timestamp",
            DateFormat('MMMM dd, yyyy • hh:mm:ss a').format(item.timestamp),
          ),
          _detailRow("UID", item.uid ?? ''),
        ]),
        const SizedBox(height: 32),
        _buildDetailSection("STORAGE VAULT URL", [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BackupColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BackupColors.border),
            ),
            child: SelectableText(
              item.url,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.url));
              FlushBar.show(context, 'Link copied to clipboard');
            },
            icon: const Icon(Iconsax.copy, size: 16),
            label: const Text("Copy Link"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 60),
        const Divider(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Spacer(),
            TextButton.icon(
              onPressed: () => _confirmDelete(item),
              icon: const Icon(Iconsax.trash, size: 18),
              label: const Text("Delete Record"),
              style: TextButton.styleFrom(foregroundColor: BackupColors.danger),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: BackupColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: BackupColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: BackupColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.cloud_sunny, size: 64, color: BackupColors.border),
          SizedBox(height: 16),
          Text(
            "Select a backup to view technical metadata",
            style: TextStyle(color: BackupColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showMobileDetailSheet(BackupModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: BackupColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BackupColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailContent(item),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResultDialog(
    BuildContext context,
    String title,
    String message, {
    String? url,
  }) {
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: BackupColors.textSecondary),
            ),
            if (url != null) ...[
              const SizedBox(height: 16),
              const Text(
                "VAULT URL",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: BackupColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BackupColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BackupColors.border),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BackupModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Backup?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will remove the backup record from the registry. The storage file remains unaffected.',
          style: TextStyle(color: BackupColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BackupColors.danger,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('backups')
          .doc(item.uid)
          .delete();
      if (!mounted) return;
      if (_selectedBackup?.uid == item.uid) {
        setState(() => _selectedBackup = null);
      }
      context.read<BackupBloc>().add(StreamBackup());
      FlushBar.show(context, 'Record removed successfully');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.cloud_cross, size: 64, color: BackupColors.border),
          const SizedBox(height: 16),
          const Text(
            "Registry is empty",
            style: TextStyle(
              color: BackupColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create a new snapshot to begin.",
            style: TextStyle(color: BackupColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Text(
        "Connection Error: $msg",
        style: const TextStyle(
          color: BackupColors.danger,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
