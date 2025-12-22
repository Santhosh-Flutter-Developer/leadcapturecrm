import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

class _TrashScreenState extends State<TrashScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _selectionMode = false;
  bool _isProcessing = false;
  final Set<String> _selectedIds = {};
  QuerySnapshot? _lastSnapshot;

  Query<Map<String, dynamic>>? _trashRef;

  @override
  void initState() {
    super.initState();
    _init();
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

  @override
  Widget build(BuildContext context) {
    if (_trashRef == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Trash')),
        body: WaitingLoading(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Back(),
        title: Text(
          _selectionMode ? 'Selected: ${_selectedIds.length}' : 'Trash',
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.close),
              onPressed: _isProcessing ? null : _clearSelection,
            ),
          if (_selectionMode && _selectedIds.isNotEmpty)
            IconButton(
              tooltip: 'Restore selected',
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: _isProcessing ? null : _restoreSelected,
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

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Trash is empty',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }

              _lastSnapshot = snapshot.data;
              final docs = snapshot.data!.docs;

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();

                  final id = doc.id;
                  final originalPath = (data['originalPath'] ?? '') as String;
                  final canRestoreTo =
                      (data['canRestoreTo'] ?? originalPath) as String;
                  final deletedAt = data['deletedAt'];
                  final innerData =
                      (data['data'] ?? {}) as Map<String, dynamic>;

                  var title =
                      innerData['title']?.toString() ??
                      innerData['name']?.toString() ??
                      canRestoreTo.split('/').last;

                  title =
                      "${title.decrypt} (${data['collection'].toString().capitalizeFirst})";

                  final selected = _selectedIds.contains(id);

                  String subtitle = originalPath;
                  if (deletedAt is Timestamp) {
                    final dt = deletedAt.toDate();
                    subtitle = 'Deleted: ${dt.listingDateTime}';
                  }

                  return ListTile(
                    onLongPress: () => _toggleSelectionMode(id),
                    onTap: () {
                      if (_selectionMode) {
                        _toggleItem(id);
                      } else {
                        _toggleSelectionMode(id);
                      }
                    },
                    leading: _selectionMode
                        ? Checkbox(
                            value: selected,
                            onChanged: _isProcessing
                                ? null
                                : (_) => _toggleItem(id),
                          )
                        : const Icon(Icons.delete_outline),
                    title: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: !_selectionMode
                        ? IconButton(
                            tooltip: 'Restore',
                            icon: const Icon(Icons.settings_backup_restore),
                            onPressed: _isProcessing
                                ? null
                                : () => _restoreSingle(doc),
                          )
                        : null,
                  );
                },
              );
            },
          ),

          if (_isProcessing)
            Container(
              color: AppColors.black.withValues(alpha: 0.2),
              child: WaitingLoading(),
            ),
        ],
      ),
    );
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
}
