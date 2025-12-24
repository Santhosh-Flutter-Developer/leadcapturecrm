import 'package:aaatp/services/database/database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '/models/models.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import '/theme/theme.dart';

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
                    const SizedBox(height: 30),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Mobile Layout
                        if (kIsMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKpiGrid(widget.isAdmin, data),
                              const SizedBox(height: 30),
                              if (widget.isAdmin) ...[
                                ChartCard(data: data),
                                const SizedBox(height: 30),
                              ],
                              _buildActivitySection(
                                context,
                                widget.isAdmin,
                                data,
                              ),
                              const SizedBox(height: 30),
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
                                  _buildKpiGrid(widget.isAdmin, data),
                                  const SizedBox(height: 30),
                                  if (widget.isAdmin) ...[
                                    ChartCard(data: data),
                                    const SizedBox(height: 30),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}

Widget _buildKpiGrid(bool isAdmin, DashboardModel data) {
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
                  ),
                ),
                // const SizedBox(width: 10),
                // SizedBox(
                //   width: 200,
                //   child: KpiCard(
                //     title: "Total Leads",
                //     value: data.totalLeads.toString(),
                //     icon: Icons.bar_chart_rounded,
                //     progress: _calculateProgress(data.totalLeads, 200),
                //     gradientColors: blueGradient,
                //     trend: 12.5,
                //   ),
                // ),
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
  final activities = isAdmin ? data.recentActivities : data.personalActivities;

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
            text: activities[index],
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Quick Actions Grid
      GridView.count(
        crossAxisCount: 3, // 3 icons in a row
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.9,
        children: isAdmin
            ? [
                QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: "Add Lead",
                  color: Colors.blue,
                  onTap: () {
                    if (kIsMobile) {
                      Sheet.showSheet(context, widget: const LeadCreate());
                    } else {
                      GeneralDialog.showRTLSheet(context, const LeadCreate());
                    }
                  },
                ),
                QuickActionCard(
                  icon: Icons.work_outline,
                  label: "Add Deal",
                  color: Colors.purple,
                  onTap: () {
                    if (kIsMobile) {
                      Sheet.showSheet(context, widget: const DealCreate());
                    } else {
                      GeneralDialog.showRTLSheet(context, const DealCreate());
                    }
                  },
                ),
                QuickActionCard(
                  icon: Icons.check_circle_outline,
                  label: "Add Task",
                  color: Colors.orange,
                  onTap: () {
                    if (kIsMobile) {
                      Sheet.showSheet(context, widget: const TasksListing());
                    } else {
                      GeneralDialog.showRTLSheet(context, const TasksListing());
                    }
                  },
                ),
              ]
            : [
                QuickActionCard(
                  icon: Icons.person_add_outlined,
                  label: "New Lead",
                  color: Colors.blue,
                  onTap: () {
                    if (kIsMobile) {
                      Sheet.showSheet(context, widget: const LeadCreate());
                    } else {
                      GeneralDialog.showRTLSheet(context, const LeadCreate());
                    }
                  },
                ),
                QuickActionCard(
                  icon: Icons.update,
                  label: "Tasks",
                  color: Colors.orange,
                  onTap: () {
                    if (kIsMobile) {
                      Sheet.showSheet(context, widget: const TasksListing());
                    } else {
                      GeneralDialog.showRTLSheet(context, const TasksListing());
                    }
                  },
                ),
                QuickActionCard(
                  icon: Icons.chat_bubble_outline,
                  label: "Chat",
                  color: Colors.green,
                  onTap: () async {
                    var uid = await Spdb.getUid() ?? '';
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: ChatListing(currentUserUid: uid),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        ChatListing(currentUserUid: uid),
                      );
                    }
                  },
                ),
              ],
      ),

      const SizedBox(height: 30),

      // Notifications Section
      Text(
        "Notifications",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
      ),
      const SizedBox(height: 15),
      if (notifications.isEmpty)
        Text(
          "No new notifications.",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
        ),
      ...notifications.map((msg) => NotificationTile(notification: msg)),

      const SizedBox(height: 30),

      // Tasks Section
      Text(
        isAdmin ? "Upcoming Deadlines" : "Your Tasks",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
      ),
      const SizedBox(height: 15),
      if (upcomingTasks.isEmpty)
        Text(
          "No upcoming tasks.",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
        )
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
}

// --- REDESIGNED WIDGETS ---

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double progress;
  final List<Color> gradientColors;
  final double? trend;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.progress,
    required this.gradientColors,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (trend ?? 0) >= 0;

    return Container(
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

class ChartCard extends StatefulWidget {
  final DashboardModel data;

  const ChartCard({super.key, required this.data});

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard>
    with SingleTickerProviderStateMixin {
  late TabController _titleController;
  int _selectedChartIndex = 0;

  final List<String> _titles = ["Leads", "Deals", "Tasks"];

  final List<Map<String, dynamic>> _chartTypes = [
    {"name": "Line", "icon": Icons.show_chart},
    {"name": "Bar", "icon": Icons.bar_chart},
    {"name": "Pie", "icon": Icons.pie_chart},
  ];

  final List<Color> _gradientColors = [
    const Color(0xff4285F4),
    const Color(0xff6A88E5),
    const Color(0xff9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TabController(length: _titles.length, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<double> _getValuesForTitle(int titleIndex) {
    switch (titleIndex) {
      case 0:
        return [
          widget.data.totalLeads.toDouble(),
          widget.data.convertedLeads.toDouble(),
          widget.data.leadsAssigned.toDouble(),
        ];
      case 1:
        return [
          widget.data.ongoingDeals.toDouble(),
          widget.data.convertedLeads.toDouble(),
          widget.data.totalLeads.toDouble(),
        ];
      case 2:
        return [
          widget.data.pendingTasks.toDouble(),
          widget.data.assignedTasks.toDouble(),
          widget.data.pendingFollowUps.toDouble(),
        ];
      default:
        return [0, 0, 0];
    }
  }

  Widget _buildChart(int titleIndex, int chartIndex) {
    final values = _getValuesForTitle(titleIndex);

    switch (_chartTypes[chartIndex]['name']) {
      case 'Line':
        return Padding(
          padding: const EdgeInsets.only(
            right: 20.0,
            left: 10,
            top: 20,
            bottom: 10,
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "D${value.toInt() + 1}",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: kTextSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    values.length,
                    (i) => FlSpot(i.toDouble(), values[i]),
                  ),
                  isCurved: true,
                  barWidth: 4,
                  color: _gradientColors.first,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: _gradientColors.first,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _gradientColors.first.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'Bar':
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Cat ${value.toInt() + 1}",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: kTextSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(
                values.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: _gradientColors[i % _gradientColors.length],
                      width: 20,
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: values.reduce(math.max) * 1.2,
                        color: kBgColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case 'Pie':
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: List.generate(values.length, (i) {
                return PieChartSectionData(
                  value: values[i],
                  radius: 60,
                  titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: _gradientColors[i % _gradientColors.length],
                );
              }),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: kBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _titleController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: kTextPrimary,
                      unselectedLabelColor: kTextSecondary,
                      labelStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      dividerColor: AppColors.transparent,
                      padding: const EdgeInsets.all(4),
                      tabs: _titles.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tiny Chart Type Toggles
                Row(
                  children: List.generate(_chartTypes.length, (index) {
                    final isSelected = _selectedChartIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChartIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kTextPrimary
                              : kTextPrimary.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _chartTypes[index]['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : kTextPrimary,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBgColor),
          SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _titleController,
              builder: (context, child) {
                return _buildChart(_titleController.index, _selectedChartIndex);
              },
            ),
          ),
        ],
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

                if (notification.type != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.type!.capitalizeFirst,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: kTextSecondary),
                  ),
                ],
              ],
            ),
          ),

          // /// UNREAD DOT (optional)
          // if (notification.isUnread == true)
          //   Container(
          //     margin: const EdgeInsets.only(top: 4),
          //     width: 8,
          //     height: 8,
          //     decoration: const BoxDecoration(
          //       color: Colors.blue,
          //       shape: BoxShape.circle,
          //     ),
          //   ),
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
  final String text;
  final bool isFirst;

  const ActivityTimelineTile({
    super.key,
    required this.text,
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
            Container(width: 2, height: 30, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0), // Align with dot
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isFirst ? kTextPrimary : kTextSecondary,
                fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
              ),
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
