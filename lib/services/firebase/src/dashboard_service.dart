import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DashboardModel> fetchDashboardData({
    required bool isAdmin,
    required String userId,
  }) async {
    try {
      final cid = await Spdb.getCid();
      if (cid == null) throw "CollectionId cannot be null";

      final totalLeads = await _fetchTotalLeads(cid);
      final convertedLeads = await _fetchConvertedLeads(cid);
      final ongoingDeals = await _fetchOngoingDeals(cid);
      final pendingTasks = await _fetchPendingTasks(cid);
      final activeEmployees = await _fetchActiveEmployees(cid);
      final assignedTasks = await _fetchAssignedTasks(cid, userId);
      final pendingFollowUps = await _fetchPendingFollowUps(cid);
      final leadsAssigned = await _fetchLeadsAssigned(cid, userId);
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

  Future<int> _fetchTotalLeads(String cid) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching total leads: $e\n$st");
      throw 'Error fetching total leads: $e';
    }
  }

  Future<int> _fetchConvertedLeads(String cid) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .where("leadsConversion", isEqualTo: true)
          .count()
          .get();

      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching converted leads: $e\n$st");
      throw 'Error fetching converted leads: $e';
    }
  }

  Future<int> _fetchOngoingDeals(String cid) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.deals.name)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching ongoing deals: $e\n$st");
      throw 'Error fetching ongoing deals: $e';
    }
  }

  Future<int> _fetchPendingTasks(String cid) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.tasks.name)
          .where("completed", isEqualTo: false)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching pending tasks: $e\n$st");
      throw 'Error fetching pending tasks: $e';
    }
  }

  Future<int> _fetchActiveEmployees(String cid) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.employees.name)
          .where("isActive", isEqualTo: true)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching active employees: $e\n$st");
      throw 'Error fetching active employees: $e';
    }
  }

  Future<int> _fetchAssignedTasks(String cid, String userId) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.tasks.name)
          .where("assignees", arrayContains: userId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching assigned tasks: $e\n$st");
      throw 'Error fetching assigned tasks: $e';
    }
  }

  Future<int> _fetchLeadsAssigned(String cid, String userId) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .where("assignedTo", isEqualTo: userId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching lead assigned: $e\n$st");
      throw 'Error fetching lead assigned: $e';
    }
  }

  Future<int> _fetchPendingFollowUps(String cid) async {
    try {
      final snap = await _firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .where("allowFollowUp", isEqualTo: true)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, st) {
      debugPrint("Error fetching pending followups: $e\n$st");
      throw 'Error fetching pending followups: $e';
    }
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
