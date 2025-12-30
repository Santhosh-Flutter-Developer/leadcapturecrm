import 'package:flutter/material.dart';

import '/models/models.dart';
import '/services/firebase/firebase.dart';
import '/theme/theme.dart';
import '/views/views.dart';

class LeadStatusReorder extends StatefulWidget {
  final List<LeadStatusModel> leadStatusList;
  const LeadStatusReorder({super.key, required this.leadStatusList});

  @override
  State<LeadStatusReorder> createState() => _LeadStatusReorderState();
}

class _LeadStatusReorderState extends State<LeadStatusReorder> {
  // Local list to manage the reordering
  final List<LeadStatusModel> _leadStatusList = [];

  @override
  void initState() {
    super.initState();
    // 1. Clone the widget list into the state list
    _leadStatusList.addAll(widget.leadStatusList);

    // 2. IMPORTANT: Ensure list is sorted by orderNumber initially
    _leadStatusList.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));

    // 3. Re-sync order numbers in case they are sparse (e.g., 1, 5, 10)
    // This ensures our list starts from a clean 1, 2, 3... state.
    _updateOrderNumbers();
  }

  void _updateOrderNumbers() {
    for (int i = 0; i < _leadStatusList.length; i++) {
      _leadStatusList[i] = _leadStatusList[i].copyWith(orderNumber: i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormWidgets.buildHeader(
              context: context,
              title: "Reorder Lead Status",
            ),

            const SizedBox(height: 8),

            // --- LIST VIEW ---
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ReorderableListView(
                  physics: const BouncingScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;

                      final item = _leadStatusList.removeAt(oldIndex);
                      _leadStatusList.insert(newIndex, item);

                      _updateOrderNumbers();
                    });
                  },

                  children: [
                    for (final (index, status) in _leadStatusList.indexed)
                      Card(
                        key: ValueKey(status.uid),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shadowColor: AppColors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(status.color),
                            child: Text(
                              status.orderNumber.toString(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Color(status.color).computeLuminance() >
                                            0.5
                                        ? AppColors.black
                                        : AppColors.white,
                                  ),
                            ),
                          ),
                          title: Text(
                            status.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                          ),
                          subtitle: Text(
                            "Drag to reorder",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey600),
                          ),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- FOOTER BUTTON ---
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      "Cancel",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.grey100,
                      foregroundColor: AppColors.grey800,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.grey300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      "Save Order",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    try {
      futureLoading(context);

      await LeadStatusService.updateLeadStatusReorder(
        leadStatusList: _leadStatusList,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      Navigator.pop(context, true);

      FlushBar.show(context, 'Status updated successfully', isSuccess: true);
    } catch (e, st) {
      await ErrorService.recordError(e, st);

      if (Navigator.canPop(context)) Navigator.pop(context);

      FlushBar.show(
        context,
        e.toString(),
        isSuccess: false,
        error: e,
        stackTrace: st,
      );
    }
  }
}
