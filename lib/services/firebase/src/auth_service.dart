import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/utils/utils.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';

class AuthService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<Map<String, dynamic>> checkLogin({
    String? employeeId,
    String? email,
    required String password,
  }) async {
    try {
      var companies = await firebase.users.get();
      debugPrint("Companies count: ${companies.docs.length}");

      if (companies.docs.isEmpty) {
        return {"status": false, "error": "Organization not found", 'st': []};
      }

      for (var data in companies.docs) {
        // ===== Employee Login =====
        if (employeeId != null && employeeId.isNotEmpty) {
          var employees = await firebase.users
              .doc(data.id)
              .collection(Collections.employees.name)
              .get();

          for (var i in employees.docs) {
            var uData = i;

            if (uData['employeeId'].toString().toLowerCase().trim() ==
                employeeId.toLowerCase().trim()) {
              var user = await firebase.users
                  .doc(data.id)
                  .collection(Collections.employees.name)
                  .doc(uData.id)
                  .get();

              if (user.exists) {
                final userData = user.data() ?? {};

                if (userData['password'].toString().decrypt != password) {
                  return {"status": false, "error": "Invalid password"};
                }

                if (userData['loginAllowed'] == false) {
                  return {
                    "status": false,
                    "error":
                        "Your login is disabled!. Please contact your administrator to enable it.",
                  };
                }

                await _trackDevice(cid: data.id, uid: user.id, isAdmin: false);

                return {
                  "status": true,
                  "collectionId": data.id,
                  "uid": user.id,
                  "userData": userData,
                };
              }
            }
          }
        }

        if (email != null && email.isNotEmpty) {
          var admins = await firebase.users
              .doc(data.id)
              .collection(Collections.admins.name)
              .get();

          for (var i in admins.docs) {
            var aData = i;

            if (aData['email'].toString().decrypt == email.trim()) {
              var admin = await firebase.users
                  .doc(data.id)
                  .collection(Collections.admins.name)
                  .doc(aData.id)
                  .get();

              if (admin.exists) {
                final adminData = admin.data() ?? {};

                // PASSWORD CHECK
                if (adminData['password'].toString().decrypt != password) {
                  return {"status": false, "error": "Invalid password"};
                }

                await _trackDevice(cid: data.id, uid: admin.id, isAdmin: true);

                return {
                  "status": true,
                  "collectionId": data.id,
                  "uid": admin.id,
                  "adminData": adminData,
                };
              }
            }
          }
        }
      }

      return {"status": false, "error": "No user found"};
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> registerCompany({
    required String name,
    required String adminEmail,
    required String adminName,
    required String password,
    File? logo,
  }) async {
    try {
      // 1. Generate a new Company Document ID first
      DocumentReference companyRef = firebase.users.doc();
      String companyId = companyRef.id;

      // 2. Upload Logo if it exists using your StorageService
      String? logoUrl;
      if (logo != null) {
        logoUrl = await StorageService.uploadImage(
          file: logo,
          folder: StorageFolder.companyLogo,
          collectionId: companyId,
        );
      }

      // 3. Create Company Root Data
      await companyRef.set({
        'companyName': name.encrypt,
        'createdAt': FieldValue.serverTimestamp(),
        'logo': logoUrl,
        'status': 'active',
      });

      // 4. Create the Super Admin in the sub-collection
      await companyRef.collection(Collections.admins.name).add({
        'name': adminName,
        'email': adminEmail,
        'password': password,
        'role': 'super_admin',
        'createdAt': FieldValue.serverTimestamp(),
        'devices': [],
        'loginAllowed': true,
      });

      return {
        "status": true,
        "message": "Organization registered successfully",
      };
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      return {"status": false, "error": e.toString()};
    }
  }

  static Future<void> _trackDevice({
    required String cid,
    required String uid,
    required bool isAdmin,
  }) async {
    try {
      if (kIsWeb) return;

      var deviceInfo = await DeviceInfo.getDeviceInfo();
      var deviceMap = deviceInfo.toMap();

      final collection = isAdmin
          ? Collections.admins.name
          : Collections.employees.name;

      var userDoc = await firebase.users
          .doc(cid)
          .collection(collection)
          .doc(uid)
          .get();

      if (!userDoc.exists) return;

      List<dynamic> devicesRaw = userDoc.data()?['devices'] ?? [];
      List<DeviceModel> devices = devicesRaw
          .map((e) => DeviceModel.fromMap(e as Map<String, dynamic>))
          .toList();

      bool deviceExists = devices.any(
        (d) => d.toMatchMap().toString() == deviceInfo.toMatchMap().toString(),
      );

      if (deviceExists) {
        devices = devices.map((d) {
          if (d.toMatchMap().toString() == deviceInfo.toMatchMap().toString()) {
            var map = d.toMap();
            if (kIsMobile) map['fcmId'] = deviceMap['fcmId'];
            map['lastLoginAt'] = DateTime.now().millisecondsSinceEpoch;
            return DeviceModel.fromMap(map);
          }
          return d;
        }).toList();

        await firebase.users.doc(cid).collection(collection).doc(uid).update({
          'devices': devices.map((d) => d.toMap()).toList(),
        });
      } else {
        await firebase.users.doc(cid).collection(collection).doc(uid).update({
          "devices": FieldValue.arrayUnion([deviceMap]),
        });
      }
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw e.toString();
    }
  }

  static Future<void> removeCurrentDeviceFcm() async {
    if (kIsWeb) return;

    var cid = await Spdb.getCid();
    var uid = await Spdb.getUid();

    try {
      var deviceInfo = await DeviceInfo.getDeviceInfo();
      var userRef = firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(uid);

      var userDoc = await userRef.get();
      if (!userDoc.exists) return;

      List<dynamic> devicesRaw = userDoc.data()?['devices'] ?? [];
      List<DeviceModel> devices = devicesRaw
          .map((e) => DeviceModel.fromMap(e as Map<String, dynamic>))
          .toList();

      devices = devices.map((d) {
        if (d.toMatchMap().toString() == deviceInfo.toMatchMap().toString()) {
          var map = d.toMap();
          map['fcmId'] = null;
          return DeviceModel.fromMap(map);
        }
        return d;
      }).toList();

      await userRef.update({'devices': devices.map((d) => d.toMap()).toList()});
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      debugPrint('Error removing device FCM ID: $e');
      await ErrorService.recordError(e, st);
      throw e.toString();
    }
  }

  Future<bool> checkUserEmailExists({
    required String email,
    String? uid,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.users;

      if (uid != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: uid);
      }

      var companies = await query.get();

      for (var i in companies.docs) {
        if (i.exists) {
          var user = await firebase.users
              .doc(i.id)
              .collection(Collections.employees.name)
              .where('email', isEqualTo: email)
              .get();
          if (user.docs.isNotEmpty) {
            return true;
          }
        }
      }

      return false;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }

  static Future<void> resetPassword({
    required Map<String, dynamic> emailData,
    required String newPassword,
  }) async {
    try {
      if (emailData['adminId'] != null) {
        await firebase.users
            .doc(emailData['companyId'])
            .collection(Collections.admins.name)
            .doc(emailData['adminId'])
            .update({'password': newPassword.encrypt});
      } else if (emailData['employeeId'] != null) {
        await firebase.users
            .doc(emailData['companyId'])
            .collection(Collections.employees.name)
            .doc(emailData['employeeId'])
            .update({
              'password': newPassword.encrypt,
              'isInitialPasswordChanged': true,
            });
      }
    } catch (e, st) {
      debugPrint("Error resetting password: $e, $st");
      await ErrorService.recordError(e, st);
    }
  }

  static Future<List<String>> getUserFcmIds({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      var userRef = firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(uid);

      var userDoc = await userRef.get();
      if (!userDoc.exists) return [];

      var userData = userDoc.data();

      List<String> fcmIds = [];

      if (userData?['devices'] != null &&
          (userData?['devices'] as List).isNotEmpty) {
        for (var i in userData?['devices']) {
          if (i['fcmId'] != null && i['fcmId'] != '') {
            fcmIds.add(i['fcmId']);
          }
        }
      }

      return fcmIds;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>?> checkEmailExists({
    required String email,
  }) async {
    try {
      var companies = await firebase.users.get();

      for (var company in companies.docs) {
        var adminQuery = await firebase.users
            .doc(company.id)
            .collection(Collections.admins.name)
            .get();

        if (adminQuery.docs.isNotEmpty) {
          for (var i in adminQuery.docs) {
            var data = i.data();
            if (data['email'].toString().decrypt == email) {
              return {
                'companyId': company.id,
                'adminId': i.id,
                'name': data['name'].toString().decrypt,
                'email': email,
              };
            }
          }
        }
      }

      return null;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> refreshLogin() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var employee = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(uid)
          .get();

      if (employee.exists) {
        var uData = employee.data() ?? {};

        return {
          "status": true,
          "collectionId": cid,
          "uid": uid,
          "userData": uData,
        };
      }

      var admin = await firebase.users
          .doc(cid)
          .collection(Collections.admins.name)
          .doc(uid)
          .get();

      if (admin.exists) {
        final adminData = admin.data() ?? {};

        return {
          "status": true,
          "collectionId": cid,
          "uid": admin.id,
          "adminData": adminData,
        };
      }

      return {"status": false, "error": "No user found"};
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw e.toString();
    }
  }

  static Future<void> saveLoginLogs({required LoginLogsModel log}) async {
    try {
      var cid = await Spdb.getCid();
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.loginLogs.name}',
        log.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating log: $e';
    }
  }

  static Future<void> saveActivityLogs({required ActivityLogModel log}) async {
    try {
      var cid = await Spdb.getCid();
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        log.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("$e, $st");
      throw "Error creating log: $e";
    }
  }
}
