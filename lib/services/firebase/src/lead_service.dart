import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/models/models.dart';

class LeadService {
  static final FirebaseConfig firebase = FirebaseConfig();
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> createLead({required LeadModel lead}) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      // Ensure the creator is in workflow
      if (uid != null && !lead.workflow.contains(uid)) {
        lead.workflow.add(uid);
      }

      // Save lead to Firestore
      final userDoc = firebase.users.doc(cid);
      final leadsRef = userDoc.collection(Collections.leads.name);

      // Generate lead number if not provided
      int leadNumber = lead.leadNumber ?? 1;
      var lastLeadSnapshot = await leadsRef
          .orderBy('leadNumber', descending: true)
          .limit(1)
          .get();
      if (lastLeadSnapshot.docs.isNotEmpty) {
        leadNumber =
            (lastLeadSnapshot.docs.first.data()['leadNumber'] ?? 0) + 1;
      }

      var leadData = lead.toMap();
      leadData['leadNumber'] = leadNumber;

      var leadDoc = await leadsRef.add(leadData);

      // Collect workflow users for notifications
      List<String> users = lead.workflow.toSet().toList();
      List<String> fcmIds = [];
      List<String> toUids = [];

      for (var i in users) {
        var userFcmIds = await AuthService.getUserFcmIds(uid: i);

        if (userFcmIds.isNotEmpty) {
          fcmIds.addAll(userFcmIds);
          toUids.add(i);
        }
      }

      var user = await Spdb.getUser();

      var notif = NotificationModel(
        title: 'Lead : ${lead.leadName}',
        message: 'New lead created by ${user.name}',
        toFcms: fcmIds,
        toUids: users,
        senderId: await Spdb.getUid(),
        type: 'Lead',
        payload: {'leadId': leadDoc.id},
      );

      await PostNotificationService.sendNotification(model: notif);
    } catch (e, st) {
      debugPrint("Error creating lead: $e\n$st");
      await ErrorService.recordError(e, st);
      throw 'Error creating lead: $e';
    }
  }

  static Future<void> updateLead({
    required String uid,
    required LeadModel lead,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.leads.name}',
        uid,
        lead.toUpdateMap(),
        activity: '${lead.leadName} has been updated',
      );

      List<String> users = lead.workflow.toSet().toList();

      users.add(lead.createdBy.uid);
      if (lead.clientId != null) users.add(lead.clientId!);

      users = users.toSet().toList();

      List<String> fcmIds = [];
      List<String> toUids = [];

      for (var i in users) {
        var userFcmIds = await AuthService.getUserFcmIds(uid: i);

        if (userFcmIds.isNotEmpty) {
          fcmIds.addAll(userFcmIds);
          toUids.add(i);
        }
      }

      var user = await Spdb.getUser();

      var notif = NotificationModel(
        title: 'Lead : ${lead.leadName}',
        message: 'Lead has been updated by ${user.name}',
        toFcms: fcmIds,
        toUids: users,
        senderId: await Spdb.getUid(),
        type: 'Lead',
        payload: {},
      );

      await PostNotificationService.sendNotification(model: notif);
    } catch (e, st) {
      debugPrint("Error updating lead: $e\n$st");
      await ErrorService.recordError(e, st);
      throw 'Error updating lead: $e';
    }
  }

  static Future<LeadModel> getLead({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var leadDoc = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(uid)
          .get();

      if (leadDoc.exists) {
        var leadsData = leadDoc.data();
        if (leadsData != null) {
          var leads = LeadModel.fromMap(leadDoc.id, leadsData);
          return leads;
        } else {
          throw 'Lead data is empty';
        }
      } else {
        throw 'Lead not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating lead: $e';
    }
  }

  static Future<Map<LeadStatusModel, List<LeadModel>>> getLeadByGroup({
    required List<LeadModel> leadList,
  }) async {
    try {
      List<LeadStatusModel> leadStatusList =
          await LeadStatusService.getAllLeadStatus();

      Map<LeadStatusModel, List<LeadModel>> groupedLeads = {
        for (var status in leadStatusList) status: [],
      };

      for (var lead in leadList) {
        final matchingStatus = leadStatusList.firstWhere(
          (status) => status.uid == lead.leadStatus,
          orElse: () => leadStatusList.first,
        );
        groupedLeads[matchingStatus]!.add(lead);
      }

      return groupedLeads;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error grouping leads: $e\n$st");
      throw 'Error grouping leads: $e';
    }
  }

  static Future<void> updateLeadStatus({
    required String uid,
    required String leadStatus,
  }) async {
    try {
      var cid = await Spdb.getCid();
      await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(uid)
          .update({'leadStatus': leadStatus});
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating lead status: $e';
    }
  }

  static Future<void> deleteLead({required String uid}) async {
    try {
      final cid = await Spdb.getCid();

      final leadDoc = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(uid)
          .get();

      if (!leadDoc.exists) {
        throw 'Lead not found or already deleted.';
      }

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(uid)
          .get();
      final data = docRef.data() as Map<String, dynamic>;
      await TrashService.moveToTrash(
        docRef: docRef.reference,
        docData: data,
        reason: 'user_deleted',
      );
      docRef.reference.delete();
      var user = await Spdb.getUser();
      ActivityLogModel activityLogModel = ActivityLogModel(
        userData: user,
        activity: '${data['leadName'] ?? 'N/A'} has been deleted',
        description: 'User has deleted an entry in ${Collections.leads.name}',
        collection: '${Collections.users.name}/$cid/${Collections.leads.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error deleting lead: $e\n$st");
      throw 'Error deleting lead: $e';
    }
  }

  static Future<void> convertLeadToDeal({required LeadModel lead}) async {
    try {
      final cid = await Spdb.getCid();

      if (cid == null || lead.uid == null) {
        throw "Missing cid or lead UID";
      }

      await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(lead.uid)
          .update({'leadsConversion': true});

      debugPrint("Lead ${lead.leadName} marked as converted.");
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error converting lead: $e\n$st");
      rethrow;
    }
  }

  static Future<void> addLeadComment({
    required String leadUid,
    required String commentText,
  }) async {
    try {
      final cid = await Spdb.getCid();
      final uid = await Spdb.getUid();

      if (cid == null || uid == null) throw "Missing cid or uid";

      final commentsRef = firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(leadUid)
          .collection('comments');

      final commentData = {
        'comment': commentText,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await commentsRef.add(commentData);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error adding lead comment: $e\n$st");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getLeadComments({
    required String leadUid,
  }) async {
    try {
      final cid = await Spdb.getCid();
      if (cid == null) throw "Missing cid";

      final commentsRef = firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(leadUid)
          .collection('comments');

      final querySnapshot = await commentsRef
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error fetching lead comments: $e\n$st");
      rethrow;
    }
  }

  static Future<void> deleteLeadComment({
    required String leadUid,
    required String commentUid,
  }) async {
    try {
      final cid = await Spdb.getCid();
      if (cid == null) throw "Missing cid";

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(leadUid)
          .collection('comments')
          .doc(commentUid)
          .get();

      final data = docRef.data() as Map<String, dynamic>;
      await TrashService.moveToTrash(
        docRef: docRef.reference,
        docData: data,
        reason: 'user_deleted',
      );
      docRef.reference.delete();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error deleting lead comment: $e\n$st");
      rethrow;
    }
  }

  static Future<List<LeadModel>> getAllLeads() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .get();

      List<LeadModel> leads = querySnapshot.docs.map((doc) {
        return LeadModel.fromMap(doc.id, doc.data());
      }).toList();

      leads.sort((a, b) => a.leadName.compareTo(b.leadName));

      return leads;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching projects: $e';
    }
  }
}
