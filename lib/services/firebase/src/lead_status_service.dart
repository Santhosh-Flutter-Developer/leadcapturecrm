import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';

class LeadStatusService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<void> createLeadStatus({
    required LeadStatusModel leadStatus,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var lastOrderNumber = 0;
      var lastDoc = await firebase.users
          .doc(cid)
          .collection(Collections.leadStatus.name)
          .orderBy('orderNumber', descending: true)
          .limit(1)
          .get();

      if (lastDoc.docs.isNotEmpty) {
        lastOrderNumber = lastDoc.docs.first.data()['orderNumber'] ?? 0;
      }

      lastOrderNumber = lastOrderNumber + 1;

      var leadStatusMap = leadStatus.toMap();
      leadStatusMap['orderNumber'] = lastOrderNumber;

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.leadStatus.name}',
        leadStatusMap,
        activity: '${leadStatus.name} has been added as a lead status',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating leadStatus: $e';
    }
  }

  static Future<void> editLeadStatus({
    required String uid,
    required LeadStatusModel leadStatus,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.leadStatus.name}',
        uid,
        leadStatus.toUpdateMap(),
        activity: '${leadStatus.name} has been updated',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating leadStatus: $e';
    }
  }

  static Future<LeadStatusModel> getLeadStatus({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var leadStatusDoc = await firebase.users
          .doc(cid)
          .collection(Collections.leadStatus.name)
          .doc(uid)
          .get();

      if (leadStatusDoc.exists) {
        var leadStatusData = leadStatusDoc.data();
        if (leadStatusData != null) {
          var leadStatus = LeadStatusModel.fromMap(
            leadStatusDoc.id,
            leadStatusData,
          );
          return leadStatus;
        } else {
          throw 'Lead Status data is empty';
        }
      } else {
        throw 'Lead Status not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating leadStatus: $e';
    }
  }

  static Future<List<LeadStatusModel>> getAllLeadStatus() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leadStatus.name)
          .orderBy('orderNumber', descending: false)
          .get();

      List<LeadStatusModel> leadStatus = querySnapshot.docs.map((doc) {
        return LeadStatusModel.fromMap(doc.id, doc.data());
      }).toList();

      return leadStatus;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching leadStatus: $e';
    }
  }

  static Future<void> updateLeadStatusReorder({
    required List<LeadStatusModel> leadStatusList,
  }) async {
    try {
      var cid = await Spdb.getCid();

      for (var i in leadStatusList) {
        await CommonService.update(
          '${Collections.users.name}/$cid/${Collections.leadStatus.name}',
          i.uid ?? '',
          {'orderNumber': i.orderNumber},
        );
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating leadStatus: $e';
    }
  }

  static Future<bool> isLeadStatusAssigned(String statusUid) async {
    try {
      var cid = await Spdb.getCid();

      final snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .where('leadStatus', isEqualTo: statusUid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error checking lead status assignment: $e\n$st");
      return false;
    }
  }

  static Future<void> deleteLeadStatus({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.leadStatus.name)
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
        activity: '${data['name'].toString().decrypt} has been deleted',
        description:
            'User has deleted an entry in ${Collections.leadStatus.name}',
        collection:
            '${Collections.users.name}/$cid/${Collections.leadStatus.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error deleting leadStatus: $e';
    }
  }
}
