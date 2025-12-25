import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';

class LeadPriorityService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<void> createLeadPriority({
    required LeadPriorityModel leadPriority,
  }) async {
    try {
      var cid = await Spdb.getCid();
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.leadPriority.name}',
        leadPriority.toMap(),
        activity: '${leadPriority.name} has been added as a lead priority',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating leadPriority: $e';
    }
  }

  static Future<void> editLeadPriority({
    required String uid,
    required LeadPriorityModel leadPriority,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.leadPriority.name}',
        uid,
        leadPriority.toUpdateMap(),
        activity: '${leadPriority.name} has been updated',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating leadPriority: $e';
    }
  }

  static Future<LeadPriorityModel> getLeadPriority({
    required String uid,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var leadPriorityDoc = await firebase.users
          .doc(cid)
          .collection(Collections.leadPriority.name)
          .doc(uid)
          .get();

      if (leadPriorityDoc.exists) {
        var leadPriorityData = leadPriorityDoc.data();
        if (leadPriorityData != null) {
          var leadPriority = LeadPriorityModel.fromMap(
            leadPriorityDoc.id,
            leadPriorityData,
          );
          return leadPriority;
        } else {
          throw 'Lead Priority data is empty';
        }
      } else {
        throw 'Lead Priority not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating leadPriority: $e';
    }
  }

  static Future<List<LeadPriorityModel>> getAllLeadPriority() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leadPriority.name)
          .get();

      List<LeadPriorityModel> leadPriority = querySnapshot.docs.map((doc) {
        return LeadPriorityModel.fromMap(doc.id, doc.data());
      }).toList();

      return leadPriority;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching leadPriority: $e';
    }
  }

  static Future<bool> isLeadPriorityAssigned(String priorityUid) async {
    try {
      var cid = await Spdb.getCid();

      final snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .where('leadPriority', isEqualTo: priorityUid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error checking lead priority assignment: $e\n$st");
      return false;
    }
  }

  static Future<void> deleteLeadPriority({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.leadPriority.name)
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
            'User has deleted an entry in ${Collections.leadPriority.name}',
        collection:
            '${Collections.users.name}/$cid/${Collections.leadPriority.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error deleting leadPriority: $e';
    }
  }
}
