import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import 'bloc/notifications_bloc.dart';

/// Pretty notification list view — search, group-by-date, pull-to-refresh, swipe actions.
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
    // Start listening to search changes for live filter
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
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Helper to format and group notifications by day label
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

  Widget _smallAvatar(String title, String type, {bool isRead = false}) {
    final initial = title.trim().isNotEmpty
        ? title.trim().first
        : type.isNotEmpty
        ? type.trim().first
        : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: isRead ? AppColors.grey300 : AppColors.blue700,
      child: Text(
        initial,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
      ),
    );
  }

  Future<void> _openDetailSheet(NotificationModel item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 12,
                  child: Column(
                    children: [
                      // Drag handle / header area
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Content area (scrollable)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CustomScrollView(
                            controller: controller,
                            slivers: [
                              SliverToBoxAdapter(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // very small avatar
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      child: Text(
                                        (item.title.isNotEmpty
                                                ? item.title[0]
                                                : '?')
                                            .toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    Text(
                                                      item.createdAt != null
                                                          ? _timeAgo(
                                                              item.createdAt!,
                                                            )
                                                          : '',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .grey600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                                icon: Icon(
                                                  Icons.close,
                                                  color: AppColors.grey600,
                                                ),
                                                tooltip: 'Close',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 12),
                              ),

                              // Message card
                              SliverToBoxAdapter(
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      item.message,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(height: 1.3),
                                    ),
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 14),
                              ),

                              // Payload heading + expand/collapse
                              SliverToBoxAdapter(
                                child: ExpansionTile(
                                  initiallyExpanded: false,
                                  title: Text(
                                    'Payload',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SelectableText(
                                        const JsonEncoder.withIndent(
                                          '  ',
                                        ).convert(item.payload),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontFamily: 'GoogleSans',
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 20),
                              ),
                              // Actions area
                              SliverToBoxAdapter(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.copy),
                                        label: Text(
                                          'Copy payload',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: json.encode(item.payload),
                                            ),
                                          );
                                          Navigator.of(ctx).pop();
                                          FlushBar.show(
                                            context,
                                            'Payload copied',
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 12),
                              ),

                              // Optional additional meta
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Recipients',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        ...item.toUids.map(
                                          (u) => Chip(
                                            label: Text(
                                              CacheService.getUserByUid(
                                                    u,
                                                  )?.name ??
                                                  '',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListSection(String sectionLabel, List<NotificationModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            sectionLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ),
        ...items.map((item) {
          final titleLower = item.title.toLowerCase();
          final messageLower = item.message.toLowerCase();
          if (_search.isNotEmpty &&
              !titleLower.contains(_search) &&
              !messageLower.contains(_search)) {
            return const SizedBox.shrink();
          }

          return Dismissible(
            key: ValueKey(item.uid ?? item.hashCode),
            direction: DismissDirection.endToStart,
            onDismissed: (_) async {
              try {
                futureLoading(context);
                await deleteNotification(item.uid ?? '');
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                FlushBar.show(context, 'Notification deleted');
                setState(() {});
              } catch (e) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                FlushBar.show(context, e.toString(), isSuccess: false);
              }
            },
            background: Container(
              color: AppColors.danger,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: AppColors.white),
            ),
            child: InkWell(
              onTap: () => _openDetailSheet(item),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey100)),
                ),
                child: Row(
                  children: [
                    _smallAvatar(item.title, item.type ?? '', isRead: false),
                    const SizedBox(width: 12),
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
                                      : (item.type ?? ''),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.createdAt != null
                                    ? _timeAgo(item.createdAt!)
                                    : '',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.grey600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return BlocProvider(
      create: (context) => NotificationsBloc()..add(StreamNotifications()),
      child: Scaffold(
        appBar: isMobile
            ? AppBar(leading: const Back(), title: Text('Notifications'))
            : AppBar(
                leading: const Back(),
                title: Text('Notifications'),
                actions: [
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search notifications',
                          prefixIcon: const Icon(Iconsax.search_normal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onEditingComplete: () =>
                            FocusManager.instance.primaryFocus!.unfocus(),
                        onTapOutside: (event) =>
                            FocusManager.instance.primaryFocus!.unfocus(),
                      ),
                    ),
                  ),
                ],
              ),
        body: BlocListener<NotificationsBloc, NotificationsState>(
          listenWhen: (prev, curr) => curr is NotificationsLoaded,
          listener: (context, state) {},
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return WaitingLoading();
              }

              if (state is NotificationsError) {
                return ErrorDisplay(error: state.message);
              }

              if (state is NotificationsLoaded) {
                final List<NotificationModel> allNotifications =
                    state.notification;

                final filteredList = _search.isEmpty
                    ? allNotifications
                    : allNotifications.where((it) {
                        final t = it.title.toLowerCase();
                        final m = it.message.toLowerCase();
                        return t.contains(_search) || m.contains(_search);
                      }).toList();

                if (filteredList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No notifications',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey600),
                          ),
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  );
                }

                final grouped = _groupByDay(filteredList);

                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView(
                    children: [
                      // search field for mobile UI
                      if (isMobile)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search notifications',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),
                      for (final entry in grouped.entries)
                        _buildListSection(entry.key, entry.value),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              }

              // fallback
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
