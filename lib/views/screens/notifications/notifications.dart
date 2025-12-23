import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/theme/theme.dart';
import 'bloc/notifications_bloc.dart';

class NotifyColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
}

class NotificationsListing extends StatefulWidget {
  const NotificationsListing({super.key});

  @override
  State<NotificationsListing> createState() => _NotificationsListingState();
}

class _NotificationsListingState extends State<NotificationsListing> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh(BuildContext context) async {
    context.read<NotificationsBloc>().add(StreamNotifications());
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Map<String, List<NotificationModel>> _groupByDay(
    List<NotificationModel> items,
  ) {
    final Map<String, List<NotificationModel>> map = {};
    final now = DateTime.now();
    for (final item in items) {
      final dt = item.createdAt ?? DateTime.now();
      final difference = DateTime(
        dt.year,
        dt.month,
        dt.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;

      String label;
      if (difference == 0) {
        label = 'Today';
      } else if (difference == -1) {
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
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc()..add(StreamNotifications()),
      child: Scaffold(
        backgroundColor: NotifyColors.background,
        appBar: AppBar(
          backgroundColor: NotifyColors.white,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Back(color: AppColors.black),
          ),
          centerTitle: false,
          title: const Text(
            "Notifications",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: NotifyColors.textPrimary,
              fontSize: 18,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: _buildHeaderSearch(),
          ),
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(child: WaitingLoading());
            }
            if (state is NotificationsError) {
              return ErrorDisplay(error: state.message);
            }
            if (state is NotificationsLoaded) {
              final filteredList = state.notification.where((it) {
                if (_search.isEmpty) return true;
                final t = it.title.toLowerCase();
                final m = it.message.toLowerCase();
                return t.contains(_search) || m.contains(_search);
              }).toList();

              if (filteredList.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView(
                    children: const [
                      SizedBox(height: 100),
                      NoData(text: "No notifications found"),
                    ],
                  ),
                );
              }

              final grouped = _groupByDay(filteredList);

              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final entry = grouped.entries.elementAt(index);
                        return _buildSection(entry.key, entry.value);
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

  Widget _buildHeaderSearch() {
    return Column(
      children: [
        Container(color: NotifyColors.border, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: NotifyColors.background,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  size: 18,
                  color: NotifyColors.textSecondary,
                ),
                hintText: 'Search title or message contents...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: NotifyColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String label, List<NotificationModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NotifyColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...items.map((item) => _buildNotificationCard(item)),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(item.uid ?? item.hashCode),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          await deleteNotification(item.uid ?? '');
          if (mounted) FlushBar.show(context, 'Notification deleted');
        },
        background: Container(
          decoration: BoxDecoration(
            color: NotifyColors.danger,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Iconsax.trash, color: Colors.white, size: 20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: NotifyColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NotifyColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _openDetailSheet(item),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _smallAvatar(item.title, item.type ?? ''),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title.isNotEmpty
                                    ? item.title
                                    : (item.type ?? 'Alert'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: NotifyColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              item.createdAt != null
                                  ? _timeAgo(item.createdAt!)
                                  : '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: NotifyColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: NotifyColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unread indicator dot
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: NotifyColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallAvatar(String title, String type) {
    final initial = title.isNotEmpty
        ? title[0]
        : (type.isNotEmpty ? type[0] : '?');
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: NotifyColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: NotifyColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _openDetailSheet(NotificationModel item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildDetailSheet(item, ctx),
    );
  }

  Widget _buildDetailSheet(NotificationModel item, BuildContext ctx) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: NotifyColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NotifyColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _smallAvatar(item.title, item.type ?? ''),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: NotifyColors.textPrimary,
                          ),
                        ),
                        Text(
                          item.type ?? 'System Notification',
                          style: const TextStyle(
                            color: NotifyColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Iconsax.close_circle,
                      color: NotifyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "MESSAGE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: NotifyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: NotifyColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "PAYLOAD DATA",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: NotifyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NotifyColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NotifyColors.border),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(item.payload),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "RECIPIENTS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: NotifyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.toUids.map((u) {
                      final user = CacheService.getUserByUid(u);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: NotifyColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NotifyColors.border),
                        ),
                        child: Text(
                          user?.name ?? u,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: NotifyColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            _buildSheetFooter(item),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetFooter(NotificationModel item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NotifyColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: json.encode(item.payload)),
                );
                FlushBar.show(context, 'Payload copied to clipboard');
              },
              icon: const Icon(Iconsax.copy, size: 18),
              label: const Text("Copy Payload"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: const Text("Acknowledge"),
              style: ElevatedButton.styleFrom(
                backgroundColor: NotifyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
