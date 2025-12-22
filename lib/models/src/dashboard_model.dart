import '/models/models.dart';

class DashboardModel {
  final int totalLeads;
  final int convertedLeads;
  final int ongoingDeals;
  final int pendingTasks;
  final int activeEmployees;
  final int assignedTasks;
  final int pendingFollowUps;
  final int leadsAssigned;
  final List<String> recentActivities;
  final List<String> personalActivities;
  final List<NotificationModel> notifications;
  final List<TaskModel> upcomingTasks;

  DashboardModel({
    required this.totalLeads,
    required this.convertedLeads,
    required this.ongoingDeals,
    required this.pendingTasks,
    required this.activeEmployees,
    this.assignedTasks = 0,
    this.pendingFollowUps = 0,
    this.leadsAssigned = 0,
    this.recentActivities = const [],
    this.personalActivities = const [],
    this.notifications = const [],
    this.upcomingTasks = const [],
  });

  factory DashboardModel.fromMap(Map<String, dynamic> map) {
    return DashboardModel(
      totalLeads: map['totalLeads'] is int
          ? map['totalLeads'] as int
          : int.tryParse(map['totalLeads']?.toString() ?? '0') ?? 0,
      convertedLeads: map['convertedLeads'] is int
          ? map['convertedLeads'] as int
          : int.tryParse(map['convertedLeads']?.toString() ?? '0') ?? 0,
      ongoingDeals: map['ongoingDeals'] is int
          ? map['ongoingDeals'] as int
          : int.tryParse(map['ongoingDeals']?.toString() ?? '0') ?? 0,
      pendingTasks: map['pendingTasks'] is int
          ? map['pendingTasks'] as int
          : int.tryParse(map['pendingTasks']?.toString() ?? '0') ?? 0,
      activeEmployees: map['activeEmployees'] is int
          ? map['activeEmployees'] as int
          : int.tryParse(map['activeEmployees']?.toString() ?? '0') ?? 0,
      assignedTasks: map['assignedTasks'] is int
          ? map['assignedTasks'] as int
          : int.tryParse(map['assignedTasks']?.toString() ?? '0') ?? 0,
      pendingFollowUps: map['pendingFollowUps'] is int
          ? map['pendingFollowUps'] as int
          : int.tryParse(map['pendingFollowUps']?.toString() ?? '0') ?? 0,
      leadsAssigned: map['leadsAssigned'] is int
          ? map['leadsAssigned'] as int
          : int.tryParse(map['leadsAssigned']?.toString() ?? '0') ?? 0,
      recentActivities:
          map['recentActivities'] != null && map['recentActivities'] is List
          ? List<String>.from(
              (map['recentActivities'] as List).map((e) => e.toString()),
            )
          : [],
      personalActivities:
          map['personalActivities'] != null && map['personalActivities'] is List
          ? List<String>.from(
              (map['personalActivities'] as List).map((e) => e.toString()),
            )
          : [],
      notifications:
          map['notifications'] != null && map['notifications'] is List
          ? List<NotificationModel>.from(
              (map['notifications'] as List).map(
                (e) => NotificationModel.fromMap(
                  e['uid'],
                  e as Map<String, dynamic>,
                ),
              ),
            )
          : [],
      upcomingTasks: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "totalLeads": totalLeads,
      "convertedLeads": convertedLeads,
      "ongoingDeals": ongoingDeals,
      "pendingTasks": pendingTasks,
      "activeEmployees": activeEmployees,
      "assignedTasks": assignedTasks,
      "pendingFollowUps": pendingFollowUps,
      "leadsAssigned": leadsAssigned,
      "recentActivities": recentActivities,
      "personalActivities": personalActivities,
      "notifications": notifications,
      "upcomingTasks": upcomingTasks.map((e) => e.toMap()).toList(),
    };
  }

  // static int _toInt(dynamic value) {
  //   return int.tryParse(value?.toString() ?? '0') ?? 0;
  // }

  // static List<String> _toStringList(dynamic value) {
  //   if (value is List) {
  //     return value.map((e) => e.toString()).toList();
  //   }
  //   return [];
  // }
}
