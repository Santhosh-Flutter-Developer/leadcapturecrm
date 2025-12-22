import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '/views/views.dart';

class SharedprefsData extends StatefulWidget {
  const SharedprefsData({super.key});

  @override
  State<SharedprefsData> createState() => _SharedprefsDataState();
}

class _SharedprefsDataState extends State<SharedprefsData> {
  Map<String, Object?> _prefs = {};
  Map<String, Object?> _filteredPrefs = {};
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, Object?> map = {};
    for (final k in keys) {
      // SharedPreferences provides typed getters; use get() to retrieve dynamic.
      final v = prefs.get(k);
      map[k] = v;
    }
    setState(() {
      _prefs = map;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    if (_query.trim().isEmpty) {
      _filteredPrefs = Map.from(_prefs);
    } else {
      final q = _query.toLowerCase();
      _filteredPrefs = _prefs.entries
          .where(
            (e) =>
                e.key.toLowerCase().contains(q) ||
                (e.value?.toString().toLowerCase().contains(q) ?? false),
          )
          .fold<Map<String, Object?>>({}, (m, e) {
            m[e.key] = e.value;
            return m;
          });
    }
  }

  Future<void> _removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // keep old value for undo
    final oldValue = prefs.get(key);
    await prefs.remove(key);
    await _loadAll();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed "$key"',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            // restore using type detection
            if (oldValue is String) {
              await prefs.setString(key, oldValue);
            } else if (oldValue is int) {
              await prefs.setInt(key, oldValue);
            } else if (oldValue is bool) {
              await prefs.setBool(key, oldValue);
            } else if (oldValue is double) {
              await prefs.setDouble(key, oldValue);
            } else if (oldValue is List<String>) {
              await prefs.setStringList(key, oldValue);
            }
            await _loadAll();
          },
        ),
      ),
    );
  }

  Future<void> _clearAll() async {
    final should = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear all SharedPreferences?',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        content: Text(
          'This will remove all saved keys and cannot be undone.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: Theme.of(context).textTheme.bodySmall),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
    if (should == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All preferences cleared.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
  }

  String _valuePreview(Object? v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    if (v is List) return '[${v.join(', ')}]';
    return v.toString();
  }

  String _typeOf(Object? v) {
    if (v == null) return 'null';
    if (v is String) return 'String';
    if (v is int) return 'int';
    if (v is bool) return 'bool';
    if (v is double) return 'double';
    if (v is List) return 'List';
    return v.runtimeType.toString();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredPrefs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        leading: Back(),
        title: Text('SharedPreferences Viewer'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_forever),
            onPressed: _prefs.isEmpty ? null : _clearAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search keys or values',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (s) {
                      setState(() {
                        _query = s;
                        _applyFilter();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_prefs.length} total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const WaitingLoading()
          : _prefs.isEmpty
          ? Center(
              child: Text(
                'No SharedPreferences keys found.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final e = items[index];
                final key = e.key;
                final value = e.value;
                final preview = _valuePreview(value);
                final type = _typeOf(value);

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    title: Text(
                      key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '$preview • $type',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Copy value',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: value?.toString() ?? 'null'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Value copied to clipboard',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete key',
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _removeKey(key),
                        ),
                      ],
                    ),
                    onTap: () async {
                      // show details dialog
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            key,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          content: SelectableText(
                            'Value: ${value?.toString() ?? 'null'}\n\nType: $type',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Close',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: value?.toString() ?? 'null',
                                  ),
                                );
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Copied value',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Copy',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
