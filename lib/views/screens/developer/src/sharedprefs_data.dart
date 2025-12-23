import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '/views/views.dart';
import '/theme/theme.dart';

class SharedPrefsColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
}

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
      map[k] = prefs.get(k);
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
          .where((e) {
            return e.key.toLowerCase().contains(q) ||
                (e.value?.toString().toLowerCase().contains(q) ?? false);
          })
          .fold<Map<String, Object?>>({}, (m, e) {
            m[e.key] = e.value;
            return m;
          });
    }
  }

  Future<void> _removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final oldValue = prefs.get(key);
    await prefs.remove(key);
    await _loadAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Removed "$key"', style: const TextStyle(fontSize: 12)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.blueAccent,
          onPressed: () async {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Purge Storage?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will remove all local SharedPreferences keys. This action is permanent.',
          style: TextStyle(color: SharedPrefsColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: SharedPrefsColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SharedPrefsColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (should == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadAll();
    }
  }

  Color _getTypeColor(Object? v) {
    if (v is String) return const Color(0xFF3B82F6);
    if (v is int || v is double) return const Color(0xFF8B5CF6);
    if (v is bool) return const Color(0xFF10B981);
    if (v is List) return const Color(0xFFF59E0B);
    return SharedPrefsColors.textSecondary;
  }

  String _typeLabel(Object? v) {
    if (v is String) return 'STR';
    if (v is int) return 'INT';
    if (v is double) return 'DBL';
    if (v is bool) return 'BOL';
    if (v is List) return 'LST';
    return 'UNK';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredPrefs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: SharedPrefsColors.background,
      appBar: AppBar(
        backgroundColor: SharedPrefsColors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Back(color: AppColors.black),
        ),
        title: const Text(
          "Shared Prefs",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: SharedPrefsColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(
              Iconsax.refresh,
              color: SharedPrefsColors.primary,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: _prefs.isEmpty ? null : _clearAll,
            icon: const Icon(
              Iconsax.trash,
              color: SharedPrefsColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Column(
            children: [
              Container(color: SharedPrefsColors.border, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (s) {
                          setState(() {
                            _query = s;
                            _applyFilter();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search keys or values...",
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: SharedPrefsColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Iconsax.search_normal,
                            size: 18,
                            color: SharedPrefsColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: SharedPrefsColors.background,
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
                    Text(
                      '${items.length} matched',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SharedPrefsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: WaitingLoading())
          : items.isEmpty
          ? _buildEmptyState()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final e = items[index];
                    return _buildPrefCard(e.key, e.value);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_filter,
            size: 48,
            color: SharedPrefsColors.border,
          ),
          const SizedBox(height: 16),
          const Text(
            "No preferences found",
            style: TextStyle(
              color: SharedPrefsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefCard(String key, Object? value) {
    final typeColor = _getTypeColor(value);
    final valStr = value?.toString() ?? 'null';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedPrefsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SharedPrefsColors.border),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(key, value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel(value),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: typeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: SharedPrefsColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeKey(key),
                    icon: const Icon(
                      Iconsax.close_circle,
                      color: SharedPrefsColors.border,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SharedPrefsColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  valStr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SharedPrefsColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionButton(Iconsax.copy, "Copy", () {
                    Clipboard.setData(ClipboardData(text: valStr));
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: SharedPrefsColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: SharedPrefsColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(String key, Object? value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "DATA TYPE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: SharedPrefsColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.runtimeType.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: SharedPrefsColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "VALUE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: SharedPrefsColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: SharedPrefsColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SharedPrefsColors.border),
              ),
              child: SelectableText(
                value?.toString() ?? 'null',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: SharedPrefsColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: value?.toString() ?? 'null'),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Iconsax.copy, size: 16),
            label: const Text("Copy Value"),
            style: ElevatedButton.styleFrom(
              backgroundColor: SharedPrefsColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
