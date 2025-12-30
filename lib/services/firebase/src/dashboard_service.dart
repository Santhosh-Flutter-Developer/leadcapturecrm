import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTimeRange _resolveDateRange(String filter, DateTimeRange? customRange) {
    final now = DateTime.now();

    switch (filter) {
      case "Today":
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );

      case "This Week":
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: start, end: now);

      case "This Month":
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

      case "Custom Date":
        if (customRange != null) {
          return customRange;
        } else {
          debugPrint("Custom date range is null, defaulting to today");
          return DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: now,
          );
        }

      default:
        return DateTimeRange(start: DateTime(2000), end: now);
    }
  }

  Future<DashboardModel> fetchDashboardData({
    required bool isAdmin,
    required String userId,
    required String filter,
    DateTimeRange? range,
  }) async {
    try {
      final cid = await Spdb.getCid();
      if (cid == null) throw "CollectionId cannot be null";

      final dateRange = _resolveDateRange(filter, range);

      final totalLeads = await _fetchTotalLeads(cid, dateRange);
      final convertedLeads = await _fetchConvertedLeads(cid, dateRange);
      final ongoingDeals = await _fetchOngoingDeals(cid, dateRange);
      final pendingTasks = await _fetchPendingTasks(cid, dateRange);
      final activeEmployees = await _fetchActiveEmployees(cid, dateRange);
      final assignedTasks = await _fetchAssignedTasks(cid, userId, dateRange);
      final pendingFollowUps = await _fetchPendingFollowUps(cid, dateRange);
      final leadsAssigned = await _fetchLeadsAssigned(cid, userId, dateRange);

      // final recentActivities = await _fetchRecentActivities(userId);
      // final personalActivities = await _fetchPersonalActivities(userId);
      final notifications = await _fetchNotifications(cid, userId);
      final upcomingTasks = await _fetchUpcomingTasks(cid);

      return DashboardModel(
        totalLeads: totalLeads,
        convertedLeads: convertedLeads,
        ongoingDeals: ongoingDeals,
        pendingTasks: pendingTasks,
        activeEmployees: activeEmployees,
        assignedTasks: assignedTasks,
        pendingFollowUps: pendingFollowUps,
        leadsAssigned: leadsAssigned,
        // recentActivities: recentActivities,
        // personalActivities: personalActivities,
        notifications: notifications,
        upcomingTasks: upcomingTasks,
      );
    } catch (e, st) {
      debugPrint("Error fetching dashboard: $e\n$st");
      throw 'Error fetching dashboard: $e';
    }
  }

  Future<int> _fetchTotalLeads(String cid, DateTimeRange range) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leads.name)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchConvertedLeads(String cid, DateTimeRange range) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leads.name)
        .where("leadsConversion", isEqualTo: true)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchOngoingDeals(String cid, DateTimeRange range) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.deals.name)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchPendingTasks(String cid, DateTimeRange range) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.tasks.name)
        .where("completed", isEqualTo: false)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchActiveEmployees(String cid, DateTimeRange range) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.employees.name)
        .where("isActive", isEqualTo: true)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchAssignedTasks(
    String cid,
    String userId,
    DateTimeRange range,
  ) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.tasks.name)
        .where("assignees", arrayContains: userId)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchLeadsAssigned(
    String cid,
    String userId,
    DateTimeRange range,
  ) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leads.name)
        .where("assignedTo", isEqualTo: userId)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<int> _fetchPendingFollowUps(String cid, DateTimeRange range) async {
    final snap = await _firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leads.name)
        .where("allowFollowUp", isEqualTo: true)
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: range.start.millisecondsSinceEpoch,
        )
        .where(
          "createdAt",
          isLessThanOrEqualTo: range.end.millisecondsSinceEpoch,
        )
        .count()
        .get();

    return snap.count ?? 0;
  }

  // Future<List<String>> _fetchRecentActivities(String userId) async {
  //   final snap = await _firestore
  //       .collection("activities")
  //       .where("userId", isEqualTo: userId)
  //       .orderBy("createdAt", descending: true)
  //       .limit(5)
  //       .get();
  //   return snap.docs.map((d) => d.data()['activity'].toString()).toList();
  // }

  // Future<List<String>> _fetchPersonalActivities(String userId) async {
  //   final snap = await _firestore
  //       .collection("personalActivities")
  //       .where("userId", isEqualTo: userId)
  //       .orderBy("createdAt", descending: true)
  //       .limit(5)
  //       .get();
  //   return snap.docs.map((d) => d.data()['activity'].toString()).toList();
  // }

  Future<List<NotificationModel>> _fetchNotifications(
    String cid,
    String userId,
  ) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.notifications.name)
          .where("toUids", arrayContains: userId)
          .orderBy("createdAt", descending: true)
          .limit(5)
          .get();

      return snap.docs
          .map((d) => NotificationModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e, st) {
      debugPrint("Error fetching notifications: $e\n$st");
      throw 'Error fetching notifications: $e';
    }
  }

  Future<List<TaskModel>> _fetchUpcomingTasks(String cid) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final snap = await FirebaseFirestore.instance
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.tasks.name)
          .where("deadline", isGreaterThan: now)
          .get();

      return snap.docs.map((d) => TaskModel.fromMap(d.id, d.data())).toList();
    } catch (e, st) {
      debugPrint("Error fetching upcoming tasks: $e\n$st");
      throw 'Error fetching upcoming tasks: $e';
    }
  }
}
