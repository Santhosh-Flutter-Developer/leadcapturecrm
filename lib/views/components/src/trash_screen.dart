import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/trash_model.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class TrashColors {
  static const Color primary = Color(0xFFEF4444);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color restore = Color(0xFF10B981);
}

class _TrashScreenState extends State<TrashScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _selectionMode = false;
  bool _isProcessing = false;
  final Set<String> _selectedIds = {};
  QuerySnapshot? _lastSnapshot;

  Query<Map<String, dynamic>>? _trashRef;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _init();

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _init() async {
    final cid = await Spdb.getCid();
    final uid = await Spdb.getUid();
    debugPrint('Trash uid: $uid');

    final ref = _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.trash.name)
        .where('deletedBy', isEqualTo: uid)
        .orderBy('deletedAt', descending: true);

    if (!mounted) return;

    setState(() {
      _trashRef = ref;
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectionMode(String id) {
    setState(() {
      if (!_selectionMode) {
        _selectionMode = true;
        _selectedIds.clear();
        _selectedIds.add(id);
      } else {
        _toggleItem(id);
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _restoreSingle(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirm = await _confirmRestore(count: 1);
    if (!confirm) return;

    try {
      setState(() => _isProcessing = true);

      await _restoreDoc(doc);

      if (mounted) {
        FlushBar.show(context, 'Item restored');
      }
    } catch (e) {
      if (mounted) {
        FlushBar.show(context, 'Restore failed: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreSelected() async {
    if (_lastSnapshot == null || _selectedIds.isEmpty) return;

    final docs = _lastSnapshot!.docs
        .where((d) => _selectedIds.contains(d.id))
        .toList();

    final confirm = await _confirmRestore(count: docs.length);
    if (!confirm) return;

    setState(() => _isProcessing = true);

    try {
      for (final doc in docs) {
        await _restoreDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
      }

      if (mounted) {
        FlushBar.show(context, 'Restored ${docs.length} item(s)');
      }

      _clearSelection();
    } catch (e) {
      if (mounted) {
        FlushBar.show(context, 'Restore failed: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreDoc(
    DocumentSnapshot<Map<String, dynamic>> trashDoc,
  ) async {
    final data = trashDoc.data() ?? {};

    final originalPath = data['originalPath'] as String? ?? '';
    final canRestoreTo = data['canRestoreTo'] as String? ?? originalPath;

    if (canRestoreTo.isEmpty) {
      throw Exception('Missing original path for restore');
    }

    final innerData = (data['data'] ?? {}) as Map<String, dynamic>;

    final originalDocRef = _firestore.doc(canRestoreTo);

    final batch = _firestore.batch();
    batch.set(originalDocRef, innerData, SetOptions(merge: false));
    batch.delete(trashDoc.reference);

    await batch.commit();
  }

  Future<bool> _confirmRestore({required int count}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Restore Item",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            count == 1
                ? "Are you sure you want to restore this item?"
                : "Are you sure you want to restore $count items?",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore, size: 16),
              label: const Text("Restore"),
              style: ElevatedButton.styleFrom(
                backgroundColor: TrashColors.restore,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupByDay(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    final now = DateTime.now();

    for (final doc in docs) {
      final data = doc.data();
      final ts = data['deletedAt'];

      DateTime dt = now;
      if (ts is Timestamp) dt = ts.toDate();

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
      map.putIfAbsent(label, () => []).add(doc);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_trashRef == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Trash')),
        body: WaitingLoading(),
      );
    }

    return Scaffold(
      backgroundColor: TrashColors.background,
      appBar: AppBar(
        backgroundColor: TrashColors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Back(color: AppColors.black),
        ),
        centerTitle: false,
        title: const Text(
          "Trash",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: TrashColors.textPrimary,
            fontSize: 18,
          ),
        ),
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(70),
        //   child: _buildHeaderSearch(),
        // ),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.close),
              color: TrashColors.textSecondary,
              onPressed: _isProcessing ? null : _clearSelection,
            ),
          if (_selectionMode && _selectedIds.isNotEmpty)
            IconButton(
              tooltip: 'Restore selected',
              icon: const Icon(Icons.settings_backup_restore),
              color: TrashColors.textSecondary,
              onPressed: _isProcessing ? null : _restoreSelected,
            ),

          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Iconsax.refresh, size: 18),
            color: TrashColors.textSecondary,
            onPressed: () => setState(() {}),
          ),
        ],
      ),

      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _trashRef!.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return WaitingLoading();
              }

              if (!snapshot.hasData) {
                return WaitingLoading();
              }

              final docs = snapshot.data!.docs;

              final filteredDocs = docs.where((doc) {
                if (_search.isEmpty) return true;

                final data = doc.data();
                final inner = (data['data'] ?? {}) as Map<String, dynamic>;

                final title = inner['title']?.toString().toLowerCase() ?? '';
                final name = inner['name']?.toString().toLowerCase() ?? '';
                final path = (data['originalPath'] ?? '')
                    .toString()
                    .toLowerCase();

                return title.contains(_search) ||
                    name.contains(_search) ||
                    path.contains(_search);
              }).toList();

              if (filteredDocs.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text("No deleted items found")),
                  ],
                );
              }

              _lastSnapshot = snapshot.data;

              final grouped = _groupByDay(filteredDocs);

              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: grouped.entries.map((entry) {
                            return _buildSection(entry.key, entry.value);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (_isProcessing)
            Container(
              color: AppColors.black.withValues(alpha: 0.2),
              child: WaitingLoading(),
            ),

          if (_selectionMode)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /// Selected Count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TrashColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${_selectedIds.length} selected",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TrashColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text("Restore"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrashColors.restore,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: _selectedIds.isEmpty || _isProcessing
                            ? null
                            : _restoreSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String label, List docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: TrashColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...docs.map((doc) => _buildTrashCard(doc)),
      ],
    );
  }

  Widget _buildTrashCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final trash = TrashModel.fromMap(doc.data());
    final id = doc.id;

    final innerData = trash.data;
    final collection = trash.collection;

    String title =
        innerData['title']?.toString() ??
        innerData['name']?.toString() ??
        'Untitled';

    title = "${title.decrypt} ";

    final time = _timeAgo(trash.deletedAt);
    final selected = _selectedIds.contains(id);

    return GestureDetector(
      // onLongPress: () => _toggleSelectionMode(id),
      onTap: () {
        if (_selectionMode) {
          _toggleItem(id);
        } else {
          _toggleSelectionMode(id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: TrashColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TrashColors.primary : TrashColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(collection),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: TrashColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          collection.capitalizeFirst,
                          style: const TextStyle(
                            fontSize: 11,
                            color: TrashColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _timeBadge(time),
                ],
              ),

              const SizedBox(height: 10),

              const Divider(height: 1, color: TrashColors.border),

              const SizedBox(height: 10),

              /// 🔹 PATH
              // _infoRow(Iconsax.folder, trash.parentPath),

              /// 🔹 ORIGINAL PATH
              // if (trash.originalPath.isNotEmpty)
              //   _infoRow(Iconsax.link, trash.originalPath),

              // /// 🔹 REASON (NEW 🔥)
              // if (trash.reason != null && trash.reason!.isNotEmpty)
              //   _infoRow(Iconsax.warning_2, trash.reason!),

              // /// 🔹 DOCUMENT ID (for debug / power users)
              // _infoRow(Iconsax.code, trash.documentId),

              // const SizedBox(height: 12),

              /// 🔹 ACTIONS
              if (!_selectionMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.folder,
                            size: 14,
                            color: TrashColors.textSecondary,
                          ),
                          const SizedBox(width: 6),

                          Expanded(
                            child: Text(
                              trash.canRestoreTo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: TrashColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    TextButton.icon(
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text("Restore"),
                      style: TextButton.styleFrom(
                        foregroundColor: TrashColors.restore,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _restoreSingle(doc),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TrashColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: TrashColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildIcon(String collection) {
    IconData icon;

    switch (collection.toLowerCase()) {
      case 'tasks':
        icon = Iconsax.task;
        break;
      case 'users':
        icon = Iconsax.user;
        break;
      case 'files':
        icon = Iconsax.document;
        break;
      default:
        icon = Iconsax.archive;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TrashColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: TrashColors.primary),
    );
  }

  // Widget _buildHeaderSearch() {
  //   return Column(
  //     children: [
  //       Container(color: TrashColors.border, height: 1),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //         child: Material(
  //           borderRadius: BorderRadius.circular(12),
  //           color: TrashColors.background,
  //           child: TextField(
  //             controller: _searchController,
  //             decoration: const InputDecoration(
  //               prefixIcon: Icon(Icons.search, size: 18),
  //               hintText: 'Search deleted items...',
  //               border: InputBorder.none,
  //               contentPadding: EdgeInsets.symmetric(vertical: 14),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
