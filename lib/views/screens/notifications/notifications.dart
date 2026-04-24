import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
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
  NotificationModel? _selectedNotification;

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

  Future<dynamic> _resolveProfileByUid(String uid) async {
    if (uid.trim().isEmpty) return null;

    final cached = CacheService.getUserByUid(uid);
    if (cached is EmployeeModel || cached is AdminModel) {
      return cached;
    }

    try {
      final employee = await EmployeeService.getEmployee(uid: uid);
      if (employee != null) return employee;
    } catch (_) {}

    try {
      final admin = await AdminService.getAdmin(uid: uid);
      if (admin != null) return admin;
    } catch (_) {}

    return null;
  }

  Future<void> _openSenderProfile(NotificationModel item) async {
    final senderUid = item.senderId?.trim() ?? '';
    if (senderUid.isEmpty) return;

    final profile = await _resolveProfileByUid(senderUid);
    if (!mounted) return;

    if (profile is EmployeeModel) {
      if (kIsMobile) {
        await Sheet.showSheet(
          context,
          widget: EmployeeDetails(employee: profile),
        );
      } else {
        await GeneralDialog.showRTLSheet(
          context,
          EmployeeDetails(employee: profile),
        );
      }
      return;
    }

    if (profile is AdminModel) {
      if (kIsMobile) {
        await Sheet.showSheet(context, widget: AdminProfile(admin: profile));
      } else {
        await GeneralDialog.showRTLSheet(context, AdminProfile(admin: profile));
      }
      return;
    }

    FlushBar.show(context, 'User profile not found', isSuccess: false);
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
          leading: const Back(color: AppColors.black),
          centerTitle: false,
          title: const Text(
            "Notifications Center",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: NotifyColors.textPrimary,
              fontSize: 18,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: NotifyColors.border, height: 1),
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
              return LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth > 1100;
                  final notifications = state.notification;
                  return isDesktop
                      ? _buildDesktopLayout(notifications)
                      : _buildMobileLayout(notifications);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// DESKTOP LAYOUT: Master-Detail Split Pane
  Widget _buildDesktopLayout(List<NotificationModel> notifications) {
    final filteredList = _filterList(notifications);
    final grouped = _groupByDay(filteredList);

    return Row(
      children: [
        // Left Side: Search & List
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: NotifyColors.white,
            border: Border(right: BorderSide(color: NotifyColors.border)),
          ),
          child: Column(
            children: [
              _buildHeaderSearch(),
              Expanded(
                child: filteredList.isEmpty
                    ? const NoData(text: "No matches found")
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          return _buildSection(
                            entry.key,
                            entry.value,
                            isDesktop: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Right Side: Detail View
        Expanded(
          child: _selectedNotification == null
              ? _buildEmptyDetailView()
              : _buildDetailContent(_selectedNotification!),
        ),
      ],
    );
  }

  /// MOBILE LAYOUT: Traditional List
  Widget _buildMobileLayout(List<NotificationModel> notifications) {
    final filteredList = _filterList(notifications);
    final grouped = _groupByDay(filteredList);

    return Column(
      children: [
        _buildHeaderSearch(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: filteredList.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      NoData(text: "No notifications found"),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return _buildSection(
                        entry.key,
                        entry.value,
                        isDesktop: false,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  List<NotificationModel> _filterList(List<NotificationModel> list) {
    final query = _search.toLowerCase();

    return list.where((it) {
      if (query.isEmpty) return true;

      return it.title.toLowerCase().contains(query) ||
          it.body.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildHeaderSearch() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: NotifyColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NotifyColors.border),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Iconsax.search_normal,
              size: 18,
              color: NotifyColors.textSecondary,
            ),
            hintText: 'Search alerts...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: NotifyColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String label,
    List<NotificationModel> items, {
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: NotifyColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildNotificationCard(item, isDesktop)),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel item, bool isDesktop) {
    final isSelected = _selectedNotification?.uid == item.uid;
    final hasSender = (item.senderId?.trim().isNotEmpty ?? false);
    final titleText = item.title.isNotEmpty
        ? item.title
        : (item.type?.name.toUpperCase() ?? 'Alert');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Iconsax.trash, color: Colors.white, size: 20),
        ),
        child: InkWell(
          onTap: () {
            if (isDesktop) {
              setState(() => _selectedNotification = item);
            } else {
              _openDetailSheet(item);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? NotifyColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? NotifyColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hasSender
                    ? InkWell(
                        onTap: () => _openSenderProfile(item),
                        borderRadius: BorderRadius.circular(12),
                        child: _smallAvatar(
                          item.title,
                          item.type?.name ?? 'info',
                        ),
                      )
                    : _smallAvatar(item.title, item.type?.name ?? 'info'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: hasSender
                                ? InkWell(
                                    onTap: () => _openSenderProfile(item),
                                    child: Text(
                                      titleText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? NotifyColors.primary
                                            : NotifyColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : Text(
                                    titleText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? NotifyColors.primary
                                          : NotifyColors.textPrimary,
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: NotifyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDetailView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.notification_bing, size: 64, color: NotifyColors.border),
          SizedBox(height: 16),
          Text(
            "Select a notification to view details",
            style: TextStyle(
              color: NotifyColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(NotificationModel item) {
    final hasSender = (item.senderId?.trim().isNotEmpty ?? false);
    return Container(
      color: NotifyColors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _smallAvatar(item.title, item.type?.name ?? 'info', size: 60),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: NotifyColors.textPrimary,
                      ),
                    ),
                    Text(
                      (item.type?.name.toUpperCase() ?? 'System Alert'),
                      style: const TextStyle(
                        color: NotifyColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat(
                  'MMMM dd, yyyy • hh:mm a',
                ).format(item.createdAt ?? DateTime.now()),
                style: const TextStyle(
                  color: NotifyColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "MESSAGE CONTENT",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NotifyColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.body,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: NotifyColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          // const SizedBox(height: 40),
          // ...[
          //   const Text(
          //     "TECHNICAL PAYLOAD",
          //     style: TextStyle(
          //       fontSize: 11,
          //       fontWeight: FontWeight.w800,
          //       color: NotifyColors.textSecondary,
          //       letterSpacing: 1,
          //     ),
          //   ),
          //   const SizedBox(height: 12),
          //   Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.all(20),
          //     decoration: BoxDecoration(
          //       color: NotifyColors.background,
          //       borderRadius: BorderRadius.circular(16),
          //       border: Border.all(color: NotifyColors.border),
          //     ),
          //     child: SelectableText(
          //       const JsonEncoder.withIndent('  ').convert(item.payload),
          //       style: const TextStyle(
          //         fontFamily: 'monospace',
          //         fontSize: 12,
          //         height: 1.5,
          //       ),
          //     ),
          //   ),
          // ],
          const Spacer(),
          Row(
            children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: json.encode(item.payload)),
                  );
                  FlushBar.show(context, 'Payload copied');
                },
                icon: const Icon(Iconsax.copy),
                label: const Text("Copy Data"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _selectedNotification = null);
                },
                icon: const Icon(Iconsax.tick_circle),
                label: const Text("Dismiss Detail"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NotifyColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallAvatar(String title, String type, {double size = 40}) {
    final initial = title.isNotEmpty
        ? title[0]
        : (type.isNotEmpty ? type[0] : '?');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: NotifyColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 3.3),
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          color: NotifyColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Future<void> _openDetailSheet(NotificationModel item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildMobileDetailSheet(item, ctx),
    );
  }

  Widget _buildMobileDetailSheet(NotificationModel item, BuildContext ctx) {
    final hasSender = (item.senderId?.trim().isNotEmpty ?? false);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: NotifyColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: NotifyColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: hasSender
                  ? InkWell(
                      onTap: () => _openSenderProfile(item),
                      borderRadius: BorderRadius.circular(20),
                      child: _smallAvatar(
                        item.title,
                        item.type?.name ?? 'info',
                        size: 60,
                      ),
                    )
                  : _smallAvatar(
                      item.title,
                      item.type?.name ?? 'info',
                      size: 60,
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: hasSender
                  ? InkWell(
                      onTap: () => _openSenderProfile(item),
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: NotifyColors.textPrimary,
                        ),
                      ),
                    )
                  : Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: NotifyColors.textPrimary,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              item.body,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: NotifyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: NotifyColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
