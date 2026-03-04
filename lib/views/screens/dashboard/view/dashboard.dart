import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/models/models.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'package:timeago/timeago.dart' as timeago;

const Color kBgColor = Color(0xFFF4F7FE);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF2B3674);
const Color kTextSecondary = Color(0xFFA3AED0);
const double kBorderRadius = 20.0;

class Dashboard extends StatefulWidget {
  final bool isAdmin;

  const Dashboard({super.key, required this.isAdmin});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String _selectedFilter = "Today";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: WaitingLoading());
          }

          if (state is DashboardError) {
            return Center(
              child: Text(
                state.message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }

          if (state is DashboardLoaded) {
            final data = state.data;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(widget.isAdmin),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Mobile Layout
                        if (kIsMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKpiGrid(context, widget.isAdmin, data),
                              const SizedBox(height: 20),
                              if (widget.isAdmin) ...[
                                LeadsSourcePieChart(leads: data.allLeads),
                                const SizedBox(height: 20),
                                DealsTimelineChart(deals: data.allDeals),
                                const SizedBox(height: 20),
                                TaskStatusPieChart(tasks: data.allTasks),
                                const SizedBox(height: 20),
                              ],
                              _buildActivitySection(
                                context,
                                widget.isAdmin,
                                data,
                              ),
                              const SizedBox(height: 20),
                              _buildRightPanel(context, widget.isAdmin, data),
                            ],
                          );
                        }

                        // Desktop/Tablet Layout
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildKpiGrid(context, widget.isAdmin, data),
                                  const SizedBox(height: 20),
                                  if (widget.isAdmin) ...[
                                    LeadsSourcePieChart(leads: data.allLeads),
                                    const SizedBox(height: 20),
                                    DealsTimelineChart(deals: data.allDeals),
                                    const SizedBox(height: 20),
                                    TaskStatusPieChart(tasks: data.allTasks),
                                    const SizedBox(height: 20),
                                  ],
                                  _buildActivitySection(
                                    context,
                                    widget.isAdmin,
                                    data,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              flex: 2,
                              child: _buildRightPanel(
                                context,
                                widget.isAdmin,
                                data,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (VersionService.version?.isUpdateNeed ?? false)
                _buildAppUpdateContainer(),
              Text(
                "Dashboard",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: kTextSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isAdmin ? "Overview Analytics" : "My Workspace",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        _buildDateFilter(context),
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff303030) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFilter,
            icon: const Icon(Icons.arrow_drop_down),
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            style: Theme.of(context).textTheme.bodySmall,
            items: const [
              DropdownMenuItem(value: "Today", child: Text("Today")),
              DropdownMenuItem(value: "This Week", child: Text("This Week")),
              DropdownMenuItem(value: "This Month", child: Text("This Month")),
              DropdownMenuItem(
                value: "Custom Date",
                child: Text("Custom Date"),
              ),
            ],
            onChanged: (value) async {
              if (value == null) return;

              setState(() => _selectedFilter = value);

              DateTimeRange? range;

              if (value == "Custom Date") {
                range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
              }
              context.read<DashboardBloc>().add(
                LoadDashboardEvent(filter: value, range: range),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppUpdateContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90E2).withValues(alpha: 0.18),
            const Color(0xFF7F53AC).withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Update Available (v${VersionService.version?.version})",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222B45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "A newer version of the app is available. Update now for better performance, features and stability.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        if (Platform.isAndroid) {
                          Navigate.route(context, AndroidUpdate());
                        } else {
                          Uri url = Uri.parse(
                            VersionService.version?.url ?? '',
                          );
                          if (await canLaunchUrl(url)) {
                            launchUrl(url);
                          }
                        }
                      } catch (e, st) {
                        FlushBar.show(context, e.toString(), isSuccess: false);
                        await ErrorService.recordError(e, st);
                      }
                    },
                    child: Text(
                      "Update Now",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildKpiGrid(BuildContext context, bool isAdmin, DashboardModel data) {
  // Define distinct colors for visual separation
  final blueGradient = [const Color(0xFF4285F4), const Color(0xFF6A88E5)];
  final purpleGradient = [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
  final orangeGradient = [const Color(0xFFFF9966), const Color(0xFFFF5E62)];
  final greenGradient = [const Color(0xFF56ab2f), const Color(0xFFa8e063)];

  return ScrollConfiguration(
    behavior: const _HorizontalDragScrollBehavior(),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: isAdmin
            ? [
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Total Leads",
                    value: data.totalLeads.toString(),
                    icon: Icons.bar_chart_rounded,
                    progress: _calculateProgress(data.totalLeads, 200),
                    gradientColors: blueGradient,
                    trend: 12.5,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(context, widget: const LeadsListing());
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const LeadsListing(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Converted",
                    value: data.convertedLeads.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    progress: _calculateProgress(
                      data.convertedLeads,
                      data.totalLeads,
                    ),
                    gradientColors: greenGradient,
                    trend: 5.2,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(context, widget: const DealsListing());
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const DealsListing(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Ongoing Deals",
                    value: data.ongoingDeals.toString(),
                    icon: Icons.work_outline_rounded,
                    progress: _calculateProgress(data.ongoingDeals, 50),
                    gradientColors: orangeGradient,
                    trend: -2.4,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(context, widget: const DealsListing());
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const DealsListing(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Active Staff",
                    value: data.activeEmployees.toString(),
                    icon: Icons.people_outline_rounded,
                    progress: _calculateProgress(data.activeEmployees, 50),
                    gradientColors: purpleGradient,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(
                          context,
                          widget: const EmployeeListing(),
                        );
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const EmployeeListing(),
                        );
                      }
                    },
                  ),
                ),
              ]
            : [
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Assigned Tasks",
                    value: data.assignedTasks.toString(),
                    icon: Icons.task,
                    progress: _calculateProgress(data.assignedTasks, 20),
                    gradientColors: blueGradient,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(context, widget: const TasksListing());
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const TasksListing(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Pending Follow-ups",
                    value: data.pendingFollowUps.toString(),
                    icon: Icons.history,
                    progress: _calculateProgress(data.pendingFollowUps, 20),
                    gradientColors: greenGradient,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(context, widget: const LeadsListing());
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const LeadsListing(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 200,
                  child: KpiCard(
                    title: "Leads Assigned",
                    value: data.leadsAssigned.toString(),
                    icon: Icons.person_search,
                    progress: _calculateProgress(data.leadsAssigned, 30),
                    gradientColors: purpleGradient,
                    onTap: () {
                      if (kIsMobile) {
                        Sheet.showSheet(context, widget: const LeadsListing());
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const LeadsListing(),
                        );
                      }
                    },
                  ),
                ),
              ],
      ),
    ),
  );
}

double _calculateProgress(int value, int maxValue) {
  if (maxValue == 0) return 0.0;
  final p = value / maxValue;
  return p > 1 ? 1 : p;
}

Widget _buildActivitySection(
  BuildContext context,
  bool isAdmin,
  DashboardModel data,
) {
  final List<ActivityItem> activities = data.recentActivities;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardColor,
      borderRadius: BorderRadius.circular(kBorderRadius),
      boxShadow: [
        BoxShadow(
          color: kTextPrimary.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAdmin ? "Recent Activity" : "Your Activity",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            Icon(Icons.more_horiz, color: kTextSecondary),
          ],
        ),
        const SizedBox(height: 20),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "No activity yet.",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (_, _) => const SizedBox(height: 15),
          itemBuilder: (context, index) => ActivityTimelineTile(
            activity: activities[index],
            isFirst: index == 0,
          ),
        ),
      ],
    ),
  );
}

Widget _buildRightPanel(
  BuildContext context,
  bool isAdmin,
  DashboardModel data,
) {
  final notifications = data.notifications;
  final upcomingTasks = data.upcomingTasks;

  return LayoutBuilder(
    builder: (context, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80, // controls card height
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    (isAdmin ? _adminActions(context) : _userActions(context))
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: SizedBox(
                              width: 80, // fixed width per card
                              child: card,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔔 NOTIFICATIONS
          _sectionTitle(context, "Notifications"),
          const SizedBox(height: 15),

          if (notifications.isEmpty)
            _emptyText(context, "No new notifications.")
          else
            ...notifications.map((msg) => NotificationTile(notification: msg)),

          const SizedBox(height: 20),

          // 📌 TASKS
          _sectionTitle(context, isAdmin ? "Upcoming Deadlines" : "Your Tasks"),
          const SizedBox(height: 15),

          if (upcomingTasks.isEmpty)
            _emptyText(context, "No upcoming tasks.")
          else
            ...upcomingTasks.map(
              (task) => TaskReminderTile(
                title: task.taskName,
                date: task.deadline != null
                    ? DateFormat('dd MMM yyyy').format(task.deadline!)
                    : '',
              ),
            ),
        ],
      );
    },
  );
}

Widget _sectionTitle(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: kTextPrimary,
    ),
  );
}

Widget _emptyText(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
  );
}

List<Widget> _adminActions(BuildContext context) => [
  QuickActionCard(
    icon: Icons.add_circle_outline,
    label: "Add Lead",
    color: Colors.blue,
    onTap: () => _openSheet(context, const LeadCreate()),
  ),
  QuickActionCard(
    icon: Icons.work_outline,
    label: "Add Deal",
    color: Colors.purple,
    onTap: () => _openSheet(context, const DealCreate()),
  ),
  QuickActionCard(
    icon: Icons.check_circle_outline,
    label: "Add Task",
    color: Colors.orange,
    onTap: () => _openSheet(context, const TasksListing()),
  ),
];

List<Widget> _userActions(BuildContext context) => [
  QuickActionCard(
    icon: Icons.person_add_outlined,
    label: "New Lead",
    color: Colors.blue,
    onTap: () => _openSheet(context, const LeadCreate()),
  ),
  QuickActionCard(
    icon: Icons.update,
    label: "Tasks",
    color: Colors.orange,
    onTap: () => _openSheet(context, const TasksListing()),
  ),
  QuickActionCard(
    icon: Icons.chat_bubble_outline,
    label: "Chat",
    color: Colors.green,
    onTap: () async {
      var uid = await Spdb.getUid() ?? '';
      _openSheet(context, ChatListing(currentUserUid: uid));
    },
  ),
];

void _openSheet(BuildContext context, Widget widget) {
  if (kIsMobile) {
    Sheet.showSheet(context, widget: widget);
  } else {
    GeneralDialog.showRTLSheet(context, widget);
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double progress;
  final List<Color> gradientColors;
  final double? trend;
  final VoidCallback onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.progress,
    required this.gradientColors,
    this.trend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (trend ?? 0) >= 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              kCardColor.withValues(alpha: 0.95),
              kCardColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ─── HEADER ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),

                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${trend!.abs()}%",
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            /// ─── VALUE ───────────────────────────────
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
            ),

            const Spacer(),

            /// ─── PROGRESS ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target",
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: kTextSecondary),
                ),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: gradientColors.first,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: kBgColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gradientColors.first,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kCardColor, kCardColor.withValues(alpha: 0.9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// ICON
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.9),
                        color.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),

                const SizedBox(height: 6),

                /// LABEL
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  Color _iconColor() {
    switch (notification.type?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _iconData() {
    switch (notification.type?.toLowerCase()) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline;
      case 'info':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(_iconData(), color: iconColor, size: 22),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  notification.createdAt!.formatDateMonthTime,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskReminderTile extends StatelessWidget {
  final String title;
  final String date;
  final bool isOverdue;
  final VoidCallback? onTap;

  const TaskReminderTile({
    super.key,
    required this.title,
    required this.date,
    this.isOverdue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isOverdue ? Colors.red : Colors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              /// ICON
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.9),
                      accentColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              /// CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
                    ),
                  ],
                ),
              ),

              /// STATUS / ARROW
              Row(
                children: [
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Overdue",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: kTextSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityTimelineTile extends StatelessWidget {
  final ActivityItem activity;
  final bool isFirst;

  const ActivityTimelineTile({
    super.key,
    required this.activity,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? Colors.blue : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  if (isFirst)
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                ],
              ),
            ),
            Container(width: 2, height: 20, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0), // Align with dot
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.page,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isFirst ? kTextPrimary : kTextSecondary,
                    fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                Text(
                  timeago.format(activity.visitedAt, locale: 'en_short'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isFirst ? kTextPrimary : kTextSecondary,
                    fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalDragScrollBehavior extends MaterialScrollBehavior {
  const _HorizontalDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
