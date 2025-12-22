import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '/theme/theme.dart';
import '/views/views.dart';
import '/constants/constants.dart';

class AppErrors extends StatefulWidget {
  const AppErrors({super.key});

  @override
  State<AppErrors> createState() => _AppErrorsState();
}

class _AppErrorsState extends State<AppErrors> {
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool _loading = false;
  List<Map<String, dynamic>> _errors = [];

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  /// Fetch last 100 errors
  Future<void> _loadErrors() async {
    setState(() => _loading = true);

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
    });
  }

  String _formatTime(DateTime? t) {
    if (t == null) return "-";
    return DateFormat("dd-MM-yyyy hh:mm a").format(t);
  }

  /// Copy text to clipboard
  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    FlushBar.show(context, 'Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Back(),
        title: Text("App Errors (Last 100)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrors,
            tooltip: "Reload",
          ),
        ],
      ),

      body: _loading
          ? WaitingLoading()
          : _errors.isEmpty
          ? Center(
              child: Text(
                "No errors found",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _errors.length,
              itemBuilder: (context, index) {
                final e = _errors[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      e["error"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _formatTime(e["time"]),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                    ),
                    children: [
                      _tile("Error", e["error"], copy: true),
                      _tile("StackTrace", e["stackTrace"], copy: true),
                      _tile("Collection Id", e["cid"]),
                      _tile("User Id", e["uid"]),
                      _tile("Device", e["device"]?.toString()),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _tile(String title, String? value, {bool copy = false}) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: SelectableText(value ?? "-"),
      trailing: copy
          ? IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copy(value ?? ""),
            )
          : null,
    );
  }
}
