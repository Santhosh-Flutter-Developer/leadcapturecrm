import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import 'bloc/activity_log_bloc.dart';

class ActivityLogsListing extends StatefulWidget {
  final bool showAppbar;

  const ActivityLogsListing({super.key, required this.showAppbar});

  @override
  State<ActivityLogsListing> createState() => _ActivityLogsListingState();
}

class _ActivityLogsListingState extends State<ActivityLogsListing> {
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

  // Helper to format and group activity log by day label
  Map<String, List<ActivityLogModel>> _groupByDay(
    List<ActivityLogModel> items,
  ) {
    final Map<String, List<ActivityLogModel>> map = {};
    final now = DateTime.now();
    for (final item in items) {
      final dt = item.createdAt;
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

  Widget _smallAvatar(
    BuildContext context,
    String title, {
    bool isRead = false,
  }) {
    final initial = title.trim().isNotEmpty ? title.trim().first : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: isRead ? AppColors.grey300 : AppColors.blue700,
      child: Text(
        initial,
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.copyWith(color: AppColors.white),
      ),
    );
  }

  Widget _buildListSection(String sectionLabel, List<ActivityLogModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            sectionLabel,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ),
        ...items.map((item) {
          final titleLower = item.activity;
          final messageLower = item.description ?? '';
          if (_search.isNotEmpty &&
              !titleLower.contains(_search) &&
              !messageLower.contains(_search)) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey100)),
            ),
            child: Row(
              children: [
                _smallAvatar(context, item.userData.name, isRead: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.activity,
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(item.createdAt),
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: AppColors.grey600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${item.description}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
      create: (context) => ActivityLogsBloc()..add(StreamActivityLogs()),
      child: Scaffold(
        appBar: isMobile
            ? AppBar(
                leading: Back(),
                title: Text(
                  'Activity Logs',
                  style: Theme.of(context).textTheme.bodyMedium!,
                ),
              )
            : AppBar(
                backgroundColor: Colors.transparent,
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
                          hintText: 'Search activity log',
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
        body: BlocListener<ActivityLogsBloc, ActivityLogsState>(
          listenWhen: (prev, curr) => curr is ActivityLogsLoaded,
          listener: (context, state) {},
          child: BlocBuilder<ActivityLogsBloc, ActivityLogsState>(
            builder: (context, state) {
              if (state is ActivityLogsLoading) {
                return WaitingLoading();
              }

              if (state is ActivityLogsError) {
                return ErrorDisplay(error: state.message);
              }

              if (state is ActivityLogsLoaded) {
                final List<ActivityLogModel> allActivityLogs =
                    state.activityLogs;

                final filteredList = _search.isEmpty
                    ? allActivityLogs
                    : allActivityLogs.where((it) {
                        final t = it.activity.toLowerCase();
                        final m = it.description?.toLowerCase() ?? '';
                        final n = it.collection.toLowerCase();
                        return t.contains(_search) ||
                            m.contains(_search) ||
                            n.contains(_search);
                      }).toList();

                if (filteredList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: NoData(text: "No activity log found"),
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
                              hintText: 'Search activity log',
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
