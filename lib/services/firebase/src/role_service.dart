import 'package:flutter/material.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';

class RoleService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<void> createRole({required RoleModel role}) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.roles.name}',
        role.toMap(),
        activity: '${role.name} has been added as a role',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating role: $e';
    }
  }

  static Future<void> editRole({
    required String uid,
    required RoleModel role,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.roles.name}',
        uid,
        role.toUpdateMap(),
        activity: '${role.name} has been updated',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating role: $e';
    }
  }

  static Future<RoleModel> getRole({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var roleDoc = await firebase.users
          .doc(cid)
          .collection(Collections.roles.name)
          .doc(uid)
          .get();

      if (roleDoc.exists) {
        var roleData = roleDoc.data();
        if (roleData != null) {
          var role = RoleModel.fromMap(roleDoc.id, roleData);
          return role;
        } else {
          throw 'Role data is empty';
        }
      } else {
        throw 'Role not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error getting role: $e';
    }
  }

  static Future<List<RoleModel>> getAllRoles() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.roles.name)
          .get();

      List<RoleModel> roles = querySnapshot.docs.map((doc) {
        return RoleModel.fromMap(doc.id, doc.data());
      }).toList();

      return roles;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching roles: $e';
    }
  }

  static Future<void> deleteRole({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var employeeAssignedDocs = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .where('role', isEqualTo: uid)
          .get();

      if (employeeAssignedDocs.docs.isNotEmpty) {
        throw 'This role is assigned to a employee. Please delete the employee first.';
      }

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.roles.name)
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
        description: 'User has deleted an entry in ${Collections.roles.name}',
        collection: '${Collections.users.name}/$cid/${Collections.roles.name}',
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

  static Future<String> getRoleByNameOrCreateRole({
    required String name,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.roles.name)
          .get();

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        if (data['name'].toString().decrypt.toLowerCase() ==
            name.toLowerCase()) {
          return doc.id;
        }
      }

      var role = RoleModel(
        name: name,
        description: '',
        createdBy: await Spdb.getUser(),
      );
      var newDoc = await firebase.users
          .doc(cid)
          .collection(Collections.roles.name)
          .add(role.toMap());

      return newDoc.id;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }
}
