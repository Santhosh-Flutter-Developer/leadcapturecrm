import 'package:aaatp/theme/src/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '/models/models.dart';
import '/views/views.dart';
import 'bloc/activity_log_bloc.dart';

class LogColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color surface = Colors.white;
}

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
    context.read<ActivityLogsBloc>().add(StreamActivityLogs());
    await Future.delayed(const Duration(milliseconds: 300));
  }

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
    final isMobile = MediaQuery.of(context).size.width < 650;

    return BlocProvider(
      create: (context) => ActivityLogsBloc()..add(StreamActivityLogs()),
      child: Scaffold(
        backgroundColor: LogColors.background,
        appBar: widget.showAppbar
            ? AppBar(
                backgroundColor: LogColors.white,
                elevation: 0,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Back(color: AppColors.black),
                ),
                centerTitle: false,
                title: const Text(
                  "Activity Logs",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: LogColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: _buildHeaderSearch(isMobile),
                ),
              )
            : null,
        body: BlocBuilder<ActivityLogsBloc, ActivityLogsState>(
          builder: (context, state) {
            if (state is ActivityLogsLoading) {
              return const Center(child: WaitingLoading());
            }
            if (state is ActivityLogsError) {
              return ErrorDisplay(error: state.message);
            }

            if (state is ActivityLogsLoaded) {
              final filteredList = state.activityLogs.where((it) {
                if (_search.isEmpty) return true;
                return it.activity.toLowerCase().contains(_search) ||
                    (it.description?.toLowerCase().contains(_search) ??
                        false) ||
                    it.collection.toLowerCase().contains(_search);
              }).toList();

              if (filteredList.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView(
                    children: const [
                      SizedBox(height: 100),
                      NoData(text: "No activity records match your search"),
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

  Widget _buildHeaderSearch(bool isMobile) {
    return Column(
      children: [
        Container(color: LogColors.border, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: LogColors.background,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  size: 18,
                  color: LogColors.textSecondary,
                ),
                hintText: 'Filter by activity, user or description...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: LogColors.textSecondary,
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

  Widget _buildSection(String label, List<ActivityLogModel> items) {
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
              color: LogColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...items.map((item) => _buildLogCard(item)),
      ],
    );
  }

  Widget _buildLogCard(ActivityLogModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LogColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LogColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(userData: item.userData, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userData.name.isNotEmpty
                            ? item.userData.name
                            : 'System User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: LogColors.textPrimary,
                        ),
                      ),
                      if (item.userData.desc != null)
                        Text(
                          item.userData.desc!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: LogColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: LogColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _timeAgo(item.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: LogColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: LogColors.border),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: LogColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.arrow_right_3,
                    size: 10,
                    color: LogColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.activity,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: LogColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: LogColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.folder_2,
                            size: 12,
                            color: LogColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.collection.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: LogColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
