import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import 'bloc/login_log_bloc.dart';

class LoginLogsListing extends StatefulWidget {
  final bool showAppbar;

  const LoginLogsListing({super.key, required this.showAppbar});

  @override
  State<LoginLogsListing> createState() => _LoginLogsListingState();
}

class _LoginLogsListingState extends State<LoginLogsListing> {
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

  // Helper to format and group login logs by day label
  Map<String, List<LoginLogsModel>> _groupByDay(List<LoginLogsModel> items) {
    final Map<String, List<LoginLogsModel>> map = {};
    final now = DateTime.now();
    for (final item in items) {
      final dt = item.loginTime;
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

  Widget _smallAvatar(String title, {bool isRead = false}) {
    final initial = title.trim().isNotEmpty ? title.trim().first : '?';
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

  Widget _buildListSection(String sectionLabel, List<LoginLogsModel> items) {
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
          var titleLower = item.user.name;
          final messageLower = item.loginAlert.device.toLowerCase();
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
                _smallAvatar(item.user.name, isRead: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.user.name,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(item.loginTime),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${item.loginAlert.device}\n${item.loginAlert.ipAddress} - ${item.loginAlert.location}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      create: (context) => LoginLogsBloc()..add(StreamLoginLogs()),
      child: Scaffold(
        appBar: isMobile
            ? AppBar(leading: const Back(), title: Text('Login Logs'))
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
                          hintText: 'Search login logs',
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
        body: BlocListener<LoginLogsBloc, LoginLogsState>(
          listenWhen: (prev, curr) => curr is LoginLogsLoaded,
          listener: (context, state) {},
          child: BlocBuilder<LoginLogsBloc, LoginLogsState>(
            builder: (context, state) {
              if (state is LoginLogsLoading) {
                return WaitingLoading();
              }

              if (state is LoginLogsError) {
                return ErrorDisplay(error: state.message);
              }

              if (state is LoginLogsLoaded) {
                final List<LoginLogsModel> allLoginLogs = state.loginLog;

                final filteredList = _search.isEmpty
                    ? allLoginLogs
                    : allLoginLogs.where((it) {
                        final t = it.loginAlert.device.toLowerCase();
                        final m = it.loginAlert.ipAddress.toLowerCase();
                        final n = it.loginAlert.location.toLowerCase();
                        return t.contains(_search) ||
                            m.contains(_search) ||
                            n.contains(_search);
                      }).toList();

                if (filteredList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.security_rounded,
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No login logs',
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
                              hintText: 'Search login logs',
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
