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
  // final BackupImportService _importer = BackupImportService();

  String _search = '';
  bool _busy = false;

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

  Widget _avatar(String text) {
    final initial = (text.isNotEmpty)
        ? text.trim().substring(0, 1).toUpperCase()
        : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BackupColors.primary,
            BackupColors.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
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
        await _showDialog(
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

  Future<void> _showDialog(
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
                  letterSpacing: 1,
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
            child: const Text(
              'Close',
              style: TextStyle(
                color: BackupColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BackupBloc()..add(StreamBackup()),
      child: Scaffold(
        backgroundColor: BackupColors.background,
        appBar: AppBar(
          backgroundColor: BackupColors.white,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Back(color: AppColors.black),
          ),
          centerTitle: false,
          title: const Text(
            "Data Backups",
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
                onPressed: () => _refresh(context),
                icon: const Icon(
                  Iconsax.refresh,
                  color: BackupColors.primary,
                  size: 20,
                ),
              ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Column(
              children: [
                Container(color: BackupColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v.trim()),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Iconsax.search_normal,
                              size: 18,
                              color: BackupColors.textSecondary,
                            ),
                            hintText: 'Filter logs by path or URL...',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: BackupColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: BackupColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _headerActionButton(
                        Iconsax.export_3,
                        "Export",
                        () => exportBackup(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

              if (items.isEmpty) return _buildEmptyState();
              final grouped = _groupByDay(items);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final entry = grouped.entries.elementAt(index);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
                              child: Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: BackupColors.textSecondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            ...entry.value.map(_buildBackupCard),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _headerActionButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _busy ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: BackupColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildBackupCard(BackupModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: BackupColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BackupColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(item.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.path,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: BackupColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BackupColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: BackupColors.border),
                        ),
                        child: Text(
                          _timeAgo(item.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: BackupColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: BackupColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _smallAction(Iconsax.copy, "Copy Link", () {
                        Clipboard.setData(ClipboardData(text: item.url));
                        FlushBar.show(context, 'URL copied');
                      }),
                      const Spacer(),
                      _smallAction(
                        Iconsax.trash,
                        "Delete",
                        () => _confirmDelete(item),
                        isDanger: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isDanger ? BackupColors.danger : BackupColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDanger ? BackupColors.danger : BackupColors.primary,
              ),
            ),
          ],
        ),
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
          'This will remove the backup record from the registry. The physical storage file will not be affected.',
          style: TextStyle(color: BackupColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: BackupColors.textSecondary),
            ),
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
      context.read<BackupBloc>().add(StreamBackup());
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.cloud_cross, size: 64, color: BackupColors.border),
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
            "Try creating a new snapshot or checking your filters.",
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
