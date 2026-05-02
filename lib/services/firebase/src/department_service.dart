import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';

class DepartmentService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<void> createDepartment({
    required DepartmentModel department,
  }) async {
    try {
      var cid = await Spdb.getCid();
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.departments.name}',
        department.toMap(),
        activity: '${department.name} has been added as a department',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating department: $e';
    }
  }

  static Future<void> editDepartment({
    required String uid,
    required DepartmentModel department,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.departments.name}',
        uid,
        department.toUpdateMap(),
        activity: '${department.name} has been updated',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating department: $e';
    }
  }

  static Future<DepartmentModel> getDepartment({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var departmentDoc = await firebase.users
          .doc(cid)
          .collection(Collections.departments.name)
          .doc(uid)
          .get();

      if (departmentDoc.exists) {
        var departmentData = departmentDoc.data();
        if (departmentData != null) {
          var department = DepartmentModel.fromMap(
            departmentDoc.id,
            departmentData,
          );
          return department;
        } else {
          throw 'Department data is empty';
        }
      } else {
        throw 'Department not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating department: $e';
    }
  }

  static Future<List<DepartmentModel>> getAllDepartments() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.departments.name)
          .get();

      List<DepartmentModel> departments = querySnapshot.docs.map((doc) {
        return DepartmentModel.fromMap(doc.id, doc.data());
      }).toList();

      return departments;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching departments: $e';
    }
  }

  static Future<void> deleteDepartment({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var subDepartmentAssignedDocs = await firebase.users
          .doc(cid)
          .collection(Collections.subDepartments.name)
          .where('department', isEqualTo: uid)
          .get();

      if (subDepartmentAssignedDocs.docs.isNotEmpty) {
        throw 'This department is assigned to a sub department. Please delete the sub department first.';
      }
      var employeeAssignedDocs = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .where('department', isEqualTo: uid)
          .get();

      if (employeeAssignedDocs.docs.isNotEmpty) {
        throw 'This department is assigned to a employee. Please delete the employee first.';
      }

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.departments.name)
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
            'User has deleted an entry in ${Collections.departments.name}',
        collection:
            '${Collections.users.name}/$cid/${Collections.departments.name}',
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

  static Future<void> restoreDepartment(DepartmentModel department) async {
    var cid = await Spdb.getCid();

    final uid = department.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("UID missing");
    }

    await firebase.users
        .doc(cid)
        .collection(Collections.departments.name)
        .doc(uid)
        .set(department.toMap());
  }

  static Future<String> getDepartmentByNameOrCreateDepartment({
    required String name,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.departments.name)
          .get();

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        if (data['name'].toString().decrypt.toLowerCase() ==
            name.toLowerCase()) {
          return doc.id;
        }
      }

      var department = DepartmentModel(
        name: name,
        description: '',
        createdBy: await Spdb.getUser(),
      );
      var newDoc = await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.departments.name}',
        department.toMap(),
        activity: '${department.name} has been added as a department',
      );
      return newDoc.id;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }
}
