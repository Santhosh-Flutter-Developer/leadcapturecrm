import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';

class SubDepartmentService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<void> createSubDepartment({
    required SubDepartmentModel subDepartment,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.subDepartments.name}',
        subDepartment.toMap(),
        activity: '${subDepartment.name} has been added as a sub department',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating subDepartment: $e';
    }
  }

  static Future<void> editSubDepartment({
    required String uid,
    required SubDepartmentModel subDepartment,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.subDepartments.name}',
        uid,
        subDepartment.toUpdateMap(),
        activity: '${subDepartment.name} has been updated',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating subDepartment: $e';
    }
  }

  static Future<SubDepartmentModel> getSubDepartment({
    required String uid,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var subDepartmentDoc = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
          .doc(uid)
          .get();

      if (subDepartmentDoc.exists) {
        var subDepartmentData = subDepartmentDoc.data();
        if (subDepartmentData != null) {
          var subDepartment = SubDepartmentModel.fromMap(
            subDepartmentDoc.id,
            subDepartmentData,
          );
          return subDepartment;
        } else {
          throw 'SubDepartment data is empty';
        }
      } else {
        throw 'SubDepartment not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error getting subDepartment: $e';
    }
  }

  static Future<List<SubDepartmentModel>> getAllSubDepartments() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
          .get();

      List<SubDepartmentModel> subDepartments = querySnapshot.docs.map((doc) {
        return SubDepartmentModel.fromMap(doc.id, doc.data());
      }).toList();

      return subDepartments;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching sub departments: $e';
    }
  }

  static Future<List<SubDepartmentModel>> getSubDepartmentsByDepId({
    required String depId,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
          .where('department', isEqualTo: depId)
          .get();

      List<SubDepartmentModel> subDepartments = querySnapshot.docs.map((doc) {
        return SubDepartmentModel.fromMap(doc.id, doc.data());
      }).toList();

      return subDepartments;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching sub departments: $e';
    }
  }

  static Future<void> deleteSubDepartment({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var employeeAssignedDocs = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .where('subDepartment', isEqualTo: uid)
          .get();

      if (employeeAssignedDocs.docs.isNotEmpty) {
        throw 'This sub department is assigned to a employee. Please delete the employee first.';
      }

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
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
            'User has deleted an entry in ${Collections.subDepartments.name}',
        collection:
            '${Collections.users.name}/$cid/${Collections.subDepartments.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }

  static Future<String> getSubDepartmentByNameOrCreateSubDepartment({
    required String name,
    String? department,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
          .get();

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        if (data['name'].toString().decrypt.toLowerCase() ==
            name.toLowerCase()) {
          return doc.id;
        }
      }

      var subDepartment = SubDepartmentModel(
        name: name,
        department: department ?? '',
        description: '',
        createdBy: await Spdb.getUser(),
      );
      var newDoc = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
          .add(subDepartment.toMap());

      return newDoc.id;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }
}
