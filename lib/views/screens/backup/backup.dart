import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import 'bloc/backup_bloc.dart';

class BackupListing extends StatefulWidget {
  const BackupListing({super.key});

  @override
  State<BackupListing> createState() => _BackupListingState();
}

class _BackupListingState extends State<BackupListing> {
  final BackupTrigger _trigger = BackupTrigger();
  final BackupImportService _importer = BackupImportService();

  // UI state
  String _search = '';
  bool _busy = false;

  // same example subcollections map you use; keep in sync with export/import
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
        label =
            '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      }

      map.putIfAbsent(label, () => []).add(item);
    }

    return map;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  Widget _avatar(String text) {
    final initial = (text.isNotEmpty)
        ? text.trim().substring(0, 1).toUpperCase()
        : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              'Backup uploaded',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            content: SelectableText(url),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(
                  'Close',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
        context.read<BackupBloc>().add(StreamBackup());
      } else {
        FlushBar.show(
          context,
          'Export completed but no download URL returned',
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() => _busy = false);
      FlushBar.show(context, 'Export failed: $e', isSuccess: false);
    }
  }

  Future<void> importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) {
        return FlushBar.show(
          context,
          'Selected file path not available',
          isSuccess: false,
        );
      }

      final file = File(path);
      setState(() => _busy = true);
      final res = await _importer.importFromFile(
        file,
        subcollectionsMap: _exampleSubcollectionsMap,
      );
      setState(() => _busy = false);

      final written = res['writtenDocs'] ?? 0;
      final warnings = (res['warnings'] as List? ?? []).cast<String>();

      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            'Import completed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documents written: $written',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (warnings.isNotEmpty) ...[
                  Text(
                    'Warnings:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 160,
                    child: SingleChildScrollView(
                      child: Text(
                        warnings.join('\n'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ] else
                  Text(
                    'No warnings',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(
                'Close',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );

      context.read<BackupBloc>().add(StreamBackup());
    } catch (e) {
      setState(() => _busy = false);
      FlushBar.show(context, 'Import failed: $e', isSuccess: false);
    }
  }

  Widget _buildBackupCard(BackupModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _avatar(item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.path,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _timeAgo(item.timestamp),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'download') {
                  // open url, or copy
                  await Clipboard.setData(ClipboardData(text: item.url));
                  FlushBar.show(
                    context,
                    'Download URL copied',
                    isSuccess: true,
                  );
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(
                        'Delete backup',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      content: Text(
                        'Delete backup record (does not delete storage file)?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(
                            'Delete',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await FirebaseFirestore.instance
                        .collection('backups')
                        .doc(item.uid)
                        .delete();
                    context.read<BackupBloc>().add(StreamBackup());
                  }
                } else if (v == 'restore') {
                  // If you have a restore endpoint or logic, hook it here
                  FlushBar.show(
                    context,
                    'Restore not implemented',
                    isSuccess: false,
                  );
                }
              },
              itemBuilder: (c) => [
                PopupMenuItem(
                  value: 'download',
                  child: Text(
                    'Copy URL',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                PopupMenuItem(
                  value: 'restore',
                  child: Text(
                    'Restore (Not Implemented)',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BackupBloc()..add(StreamBackup()),
      child: Scaffold(
        appBar: AppBar(
          leading: const Back(),
          title: Text('Backups'),
          elevation: 0.5,
          centerTitle: false,
          bottom: kIsMobile
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.grey50,
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _search = v.trim()),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.search_normal),
                                hintText: 'Search backups by path or url',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          label: Text(
                            'Quick export',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.white),
                          ),
                          onPressed: _busy ? null : () => exportBackup(context),
                          icon: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Iconsax.export_3,
                                  color: AppColors.white,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _busy
              ? null
              : () async {
                  final picked = await showModalBottomSheet<String>(
                    context: context,
                    builder: (c) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Iconsax.export_3),
                              title: Text(
                                'Export backup',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () => Navigator.pop(c, 'export'),
                            ),
                            ListTile(
                              leading: const Icon(Iconsax.import),
                              title: Text(
                                'Import backup (JSON)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () => Navigator.pop(c, 'import'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  if (picked == 'export') await exportBackup(context);
                  if (picked == 'import') await importBackup(context);
                },
          label: Text('Backup', style: Theme.of(context).textTheme.bodySmall),
          icon: const Icon(Icons.backup_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: BlocBuilder<BackupBloc, BackupState>(
          builder: (context, state) {
            if (state is BackupLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BackupError) {
              return Center(
                child: Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }

            if (state is BackupLoaded) {
              final allBackup = state.backups.where((b) {
                if (_search.isEmpty) return true;
                final s = _search.toLowerCase();
                return b.path.toLowerCase().contains(s) ||
                    b.url.toLowerCase().contains(s);
              }).toList();

              if (allBackup.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Icon(
                          Icons.backup_rounded,
                          size: 64,
                          color: AppColors.grey300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No backups found',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey700),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final grouped = _groupByDay(allBackup);

              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 90, top: 8),
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                        ),
                      ),
                      ...entry.value.map(_buildBackupCard),
                    ],
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
