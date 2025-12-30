import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';

class EmployeeService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<bool> checkEmployeeIdExists({
    required String employeeId,
  }) async {
    try {
      var lowerCaseEmployeeId = employeeId.toLowerCase();
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .where('lowerCaseEmployeeId', isEqualTo: lowerCaseEmployeeId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating employee: $e';
    }
  }

  static Future<void> createEmployee({required EmployeeModel employee}) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.employees.name}',
        employee.toMap(),
        activity: '${employee.name} has been added as a employee',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating employee: $e';
    }
  }

  static Future<void> editEmployee({
    required String uid,
    required EmployeeModel employee,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.employees.name}',
        uid,
        employee.toUpdateMap(),
        activity: '${employee.name} has been updated',
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating employee: $e';
    }
  }

  static Future<EmployeeModel?> getEmployee({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      if (uid.isEmpty) return null;
      var employeeDoc = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(uid)
          .get();

      if (employeeDoc.exists) {
        var employeeData = employeeDoc.data();
        if (employeeData != null) {
          var employee = EmployeeModel.fromMap(employeeDoc.id, employeeData);
          return employee;
        }
        // else {
        //   throw 'Employee data is empty';
        // }
      }
      // else {
      //   throw 'Employee not found, $uid';
      // }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error getting employee: $e';
    }
    return null;
  }

  static Future<List<EmployeeModel>> getAllEmployees({
    bool? excludeCurrentUser,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var query = firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .where('isActive', isEqualTo: true);

      if (excludeCurrentUser ?? false) {
        var uid = await Spdb.getUid();
        query = query.where(FieldPath.documentId, isNotEqualTo: uid);
      }

      var querySnapshot = await query.get();

      List<EmployeeModel> employees = querySnapshot.docs.map((doc) {
        return EmployeeModel.fromMap(doc.id, doc.data());
      }).toList();

      employees.sort((a, b) => a.name.compareTo(b.name));

      return employees;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching reporting-to employees: $e';
    }
  }

  static Future<void> deleteEmployeeImage({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var employee = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(uid)
          .get();
      var profileImageUrl = employee.data()?['profileImageUrl'];
      if (profileImageUrl != null) {
        await StorageService.deleteImage(profileImageUrl);
      }

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.employees.name}',
        uid,
        {'profileImageUrl': null},
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error deleting employee: $e';
    }
  }

  static Future<List<String>> getEmployeeWorkflow() async {
    try {
      List<String> workflow = [];
      var currentUid = await Spdb.getUid();
      String? uid = currentUid;

      Set<String> visited = {};

      while (uid != null && uid.isNotEmpty) {
        if (visited.contains(uid)) {
          break;
        }
        visited.add(uid);

        var employee = await getEmployee(uid: uid);

        if (employee != null) {
          if (employee.reportingTo != null &&
              employee.reportingTo!.isNotEmpty) {
            for (var reportUid in employee.reportingTo!) {
              workflow.add(reportUid);
            }

            uid = employee.reportingTo!.first;
          } else {
            uid = null;
          }
        }
      }

      workflow.remove(currentUid);

      return workflow;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error: $e\n$st");
      throw 'Error creating employee workflow: $e';
    }
  }

  static Future<List<String>> getUserWorkflow({String? userId}) async {
    try {
      List<String> workflow = [];
      var currentUid = await Spdb.getUid();
      String? uid = userId ?? currentUid;

      Set<String> visited = {};

      while (uid != null && uid.isNotEmpty) {
        if (visited.contains(uid)) break;
        visited.add(uid);

        dynamic user;

        try {
          user = await getEmployee(uid: uid);
        } catch (_) {
          try {
            user = await AdminService.getAdmin(uid: uid);
          } catch (_) {
            break;
          }
        }

        if (user is EmployeeModel) {
          if (user.reportingTo != null && user.reportingTo!.isNotEmpty) {
            workflow.addAll(user.reportingTo!);
            uid = user.reportingTo!.first;
            continue;
          } else {
            break;
          }
        }

        if (user is AdminModel) {
          break;
        }
      }

      workflow.remove(currentUid);
      return workflow;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error: $e\n$st");
      throw 'Error creating workflow: $e';
    }
  }

  static Future<String?> getEmployeeById({required String employeeId}) async {
    try {
      var cid = await Spdb.getCid();

      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .where('employeeId', isEqualTo: employeeId)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return null;
      } else {
        return querySnapshot.docs.first.id;
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }

  static Future<bool> isEmployeeAssigned(String employeeUid) async {
    try {
      var cid = await Spdb.getCid();

      final taskSnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .where('assignees', arrayContains: employeeUid)
          .limit(1)
          .get();
      if (taskSnapshot.docs.isNotEmpty) return true;

      final projectSnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.projects.name)
          .where('teamMembers', arrayContains: employeeUid)
          .limit(1)
          .get();
      if (projectSnapshot.docs.isNotEmpty) return true;

      final leadSnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .where('assignedTo', arrayContains: employeeUid)
          .limit(1)
          .get();
      if (leadSnapshot.docs.isNotEmpty) return true;

      final dealSnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.deals.name)
          .where('assignedTo', arrayContains: employeeUid)
          .limit(1)
          .get();
      if (dealSnapshot.docs.isNotEmpty) return true;

      final chatSnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.chats.name)
          .where('participants', arrayContains: employeeUid)
          .limit(1)
          .get();
      if (chatSnapshot.docs.isNotEmpty) return true;

      return false;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error checking employee assignment: $e\n$st");
      return false;
    }
  }

  static Future<void> deleteEmployee({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(uid)
          .get();
      final data = docRef.data() as Map<String, dynamic>;
      await TrashService.moveToTrash(
        docRef: docRef.reference,
        docData: data,
        reason: 'user_deleted',
      );

      await docRef.reference.delete();
      var user = await Spdb.getUser();
      ActivityLogModel activityLogModel = ActivityLogModel(
        userData: user,
        activity: '${data['name'].toString().decrypt} has been deleted',
        description:
            'User has deleted an entry in ${Collections.employees.name}',
        collection:
            '${Collections.users.name}/$cid/${Collections.employees.name}',
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
}
