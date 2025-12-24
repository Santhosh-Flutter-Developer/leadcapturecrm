import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '/constants/constants.dart';
import '/views/views.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

class CalendarEventScreen extends StatelessWidget {
  final bool showAppbar;
  const CalendarEventScreen({super.key, this.showAppbar = false});

  @override
  Widget build(BuildContext context) {
    // Replace with your actual Bloc construction or injection
    return BlocProvider(
      create: (_) => EventBloc()..add(StreamEvent()),
      child: CalendarDisplay(showAppbar: showAppbar),
    );
  }
}

class CalendarDisplay extends StatefulWidget {
  final bool showAppbar;
  const CalendarDisplay({super.key, this.showAppbar = true});

  @override
  State<CalendarDisplay> createState() => _CalendarDisplayState();
}

class _CalendarDisplayState extends State<CalendarDisplay> {
  CalendarView _currentView = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // --- HELPERS ---

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final fmt = DateFormat('hh:mm a');
    return "${fmt.format(start)} - ${fmt.format(end)}";
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _previousMonth() => setState(
    () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1),
  );
  void _nextMonth() => setState(
    () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                "Calendar",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: LogColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            )
          : null,
      backgroundColor: const Color(0xFFF8F9FE),
      body: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventError) {
            return Center(
              child: Text(
                state.message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }

          if (state is EventLoaded) {
            return SafeArea(
              child: Column(
                children: [
                  _buildViewSwitcher(),
                  if (_currentView != CalendarView.month)
                    _buildHorizontalDatePicker(),
                  Expanded(child: _buildBody(state.events)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            _buildSwitchTab('Day', CalendarView.day),
            _buildSwitchTab('Week', CalendarView.week),
            _buildSwitchTab('Month', CalendarView.month),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTab(String label, CalendarView view) {
    bool isSelected = _currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = view),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF5C59D4) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 30,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index - 3));
          bool isSelected = _isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5C59D4) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF5C59D4).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(List<EventModel> events) {
    switch (_currentView) {
      case CalendarView.day:
        return _buildDayView(events);
      case CalendarView.week:
        return _buildWeekView(events);
      case CalendarView.month:
        return _buildMonthView(events);
    }
  }

  Widget _buildDayView(List<EventModel> events) {
    final dayEvents = events
        .where((e) => _isSameDay(e.eventDateTime, _selectedDate))
        .toList();

    if (dayEvents.isEmpty) {
      return Center(
        child: Text(
          "No events for today",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final e = dayEvents[index];
        return EventCard(
          title: e.eventName,
          category: e.eventDescription,
          categoryColor: const Color(0xFFE8E7FF),
          textColor: const Color(0xFF5C59D4),
          time: _formatTimeRange(e.eventDateTime, e.eventEndDateTime),
          avatars: e.eventAttendes,
          onTap: () {
            if (kIsDesktop) {
              GeneralDialog.showRTLSheet(context, EventEdit(uid: e.uid ?? ''));
            } else {
              Sheet.showSheet(context, widget: EventEdit(uid: e.uid ?? ''));
            }
          },
          completed: e.completed,
        );
      },
    );
  }

  Widget _buildWeekView(List<EventModel> events) {
    DateTime firstDayOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 7,
      itemBuilder: (context, index) {
        DateTime day = firstDayOfWeek.add(Duration(days: index));
        final count = events
            .where((e) => _isSameDay(e.eventDateTime, day))
            .length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: () {
              if (count == 0) {
                if (kIsDesktop) {
                  GeneralDialog.showRTLSheet(
                    context,
                    EventCreate(selectedDate: day),
                  );
                } else {
                  Sheet.showSheet(
                    context,
                    widget: EventCreate(selectedDate: day),
                  );
                }
              } else {
                showInfoGeneralDialog(
                  context,
                  title: 'Events on ${day.day}/${day.month}/${day.year}',
                  description:
                      'You have $count event(s) scheduled for this day.',
                  items: events
                      .where((e) => _isSameDay(e.eventDateTime, day))
                      .toList(),
                );
              }
            },
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      DateFormat('E').format(day),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    count == 0 ? "No events" : "$count Events scheduled",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthView(List<EventModel> events) {
    int daysInMonth = _getDaysInMonth(_focusedMonth.year, _focusedMonth.month);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const Icon(Icons.calendar_month, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int dayNum = index + 1;
              DateTime date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayNum,
              );
              bool isToday = _isSameDay(date, DateTime.now());
              final dayEvents = events
                  .where((e) => _isSameDay(e.eventDateTime, date))
                  .toList();
              bool hasEvents = dayEvents.isNotEmpty;

              return InkWell(
                onTap: () {
                  if (hasEvents) {
                    showInfoGeneralDialog(
                      context,
                      title: 'Events on ${date.day}/${date.month}/${date.year}',
                      description:
                          'You have ${dayEvents.length} event(s) scheduled for this day.',
                      items: events
                          .where((e) => _isSameDay(e.eventDateTime, date))
                          .toList(),
                    );
                  } else {
                    if (kIsDesktop) {
                      GeneralDialog.showRTLSheet(
                        context,
                        EventCreate(selectedDate: date),
                      );
                    } else {
                      Sheet.showSheet(
                        context,
                        widget: EventCreate(selectedDate: date),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF5C59D4) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day Number and Event Count Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$dayNum',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isToday ? Colors.white : Colors.black,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                          if (hasEvents)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(
                                        0xFF5C59D4,
                                      ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${dayEvents.length}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isToday
                                          ? Colors.white
                                          : const Color(0xFF5C59D4),
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Names Scroll View
                      if (hasEvents)
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: dayEvents.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    e.eventName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          height: 1.1,
                                          color: isToday
                                              ? Colors.white.withValues(
                                                  alpha: 0.9,
                                                )
                                              : Colors.black87,
                                        ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void showInfoGeneralDialog(
    BuildContext context, {
    required String title,
    required String description,
    required List<EventModel> items,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Description
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  /// Scrollable list
                  Expanded(
                    child: Scrollbar(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              if (kIsDesktop) {
                                GeneralDialog.showRTLSheet(
                                  context,
                                  EventEdit(uid: items[index].uid ?? ''),
                                );
                              } else {
                                Sheet.showSheet(
                                  context,
                                  widget: EventEdit(
                                    uid: items[index].uid ?? '',
                                  ),
                                );
                              }
                            },
                            title: Text(items[index].eventName),
                            subtitle: Text(
                              items[index].eventDescription.isNotEmpty
                                  ? items[index].eventDescription
                                  : "No description",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Column(
                              children: [
                                Text(
                                  items[index].eventDateTime.formatTime,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  items[index].eventEndDateTime.formatTime,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Close button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "CLOSE",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      /// Animation
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String category;
  final Color categoryColor;
  final Color textColor;
  final String time;
  final List<String> avatars;
  final bool completed;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.textColor,
    required this.time,
    required this.avatars,
    required this.completed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  width: 100,
                  child: Stack(
                    children: List.generate(avatars.length, (index) {
                      return Positioned(
                        left: index * 20.0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundImage: NetworkImage(avatars[index]),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Icon(
                  Icons.check_circle_outline,
                  size: 24,
                  color: completed ? AppColors.success : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
