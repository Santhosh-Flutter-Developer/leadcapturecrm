/*
    Copyright 2024 Srisoftwarez. All rights reserved.
    Use of this source code is governed by a BSD-style license that can be
    found in the LICENSE file.
  */

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:leadcapture/models/src/activity_log_model.dart';
import 'package:leadcapture/models/src/filter_model.dart';
import 'package:leadcapture/models/src/notification_model.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';

// Project imports:
import '/constants/constants.dart';
import '/services/services.dart';

class WorkPermissionService {
  static FirebaseConfig firebase = FirebaseConfig();

  static Future<int> permissionsCount() async {
    try {
      var cid = await Spdb.getCid();
      var userId = await Spdb.getUid();

      if (cid == null || userId == null) return 0;

      final snap = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snap.count ?? 0;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw "Permission count failed: $e";
    }
  }

  static Future<int> permissionRequestCount() async {
    try {
      var cid = await Spdb.getCid();

      var permissionsCount = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .count()
          .get();

      return permissionsCount.count ?? 0;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorkPermissionModel>> permissionListing({
    required FilterModel filter,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var userId = await Spdb.getUid();
      if (cid == null || userId == null || userId.isEmpty) {
        throw "User not logged in or company not found";
      }

      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where('userId', isEqualTo: userId)
          .orderBy('created', descending: true)
          .limit(filter.pageLimit)
          .get(const GetOptions(source: Source.serverAndCache));

      print("Permissions found: ${querySnapshot.docs.length}");

      return querySnapshot.docs.map((doc) {
        var data = doc.data();
        data['uid'] = doc.id;
        return WorkPermissionModel.fromMap(data);
      }).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorkPermissionModel>> permissionRequestListing({
    required FilterModel filter,
  }) async {
    try {
      List<Map<String, dynamic>> data = [];
      var cid = await Spdb.getCid();

      int skipCount = (filter.pageNumber - 1) * filter.pageLimit;

      var permissionsQuery = firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where(
            'created',
            isGreaterThanOrEqualTo: filter.fromDate.millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: filter.toDate.millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true)
          .limit(filter.pageLimit);

      if (skipCount > 0) {
        var previousPageSnapshot = await permissionsQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );
        if (previousPageSnapshot.docs.length >= skipCount) {
          var lastVisible = previousPageSnapshot.docs[skipCount - 1];

          permissionsQuery = permissionsQuery.startAfterDocument(lastVisible);
        }
      }

      var permissions = await permissionsQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (permissions.docs.isNotEmpty) {
        for (var i in permissions.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(dList);
        }
      }

      return data.map((e) => WorkPermissionModel.fromMap(e)).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<Map<String, dynamic>>> allPermissionListing() async {
    try {
      List<Map<String, dynamic>> data = [];

      var cid = await Spdb.getCid();
      var userId = await Spdb.getUid();
      // if (userId == null || userId.isEmpty) {
      //   throw "User not logged in";
      // }

      var permissions = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where('userId', isEqualTo: userId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (permissions.docs.isNotEmpty) {
        for (var i in permissions.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(dList);
        }
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorkPermissionModel>> userPermissionListing({
    required String userId,
  }) async {
    try {
      List<Map<String, dynamic>> data = [];

      var cid = await Spdb.getCid();

      var permissions = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .where('userId', isEqualTo: userId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (permissions.docs.isNotEmpty) {
        for (var i in permissions.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(dList);
        }
      }
      return data.map((e) => WorkPermissionModel.fromMap(e)).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> createPermission({
    required WorkPermissionModel model,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();
      var user = await Spdb.getUser();

      if (uid == null || user.name.isEmpty) {
        throw Exception("User not logged in.");
      }

      final docRef = firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc();

      model = model.copyWith(
        uid: docRef.id,
        userId: uid,
        userName: user.name,
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      // ✅ SAVE PERMISSION
      await docRef.set(model.toMap());

      /// 👉 EXISTING ATTENDANCE LOGIC
      DateTime from = model.from;

      int start = DateTime(
        from.year,
        from.month,
        from.day,
      ).millisecondsSinceEpoch;

      int end = DateTime(
        from.year,
        from.month,
        from.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      final attendanceSnap = await firebase.users
          .doc(cid)
          .collection(Collections.attendance.name)
          .where('userUid', isEqualTo: uid)
          .where('created', isGreaterThanOrEqualTo: start)
          .where('created', isLessThanOrEqualTo: end)
          .limit(1)
          .get();

      if (attendanceSnap.docs.isNotEmpty) {
        final punchId = attendanceSnap.docs.first.id;

        await AttendanceService.addPermissionToPunch(
          punchId: punchId,
          permissionType: model.type,
        );
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> sendNotification(
    String userName,
    String reason,
    DateTime from,
    DateTime to,
  ) async {
    var cid = await Spdb.getCid();
    List<String> receiverFcmIds = [];
    var admins = await firebase.users
        .doc(cid)
        .collection(Collections.users.name)
        .where('type', isEqualTo: 'admin')
        .get();

    for (var i in admins.docs) {
      var fcmId = i["fcmId"];
      if (fcmId != null && fcmId.isNotEmpty) {
        receiverFcmIds.add(fcmId);
      }
    }

    List<String> data = [
      "User : $userName - ",
      "Duration : ${to.difference(from).inHours} hours and ${to.difference(from).inMinutes % 60} minutes - ",
      "Reason : $reason",
    ];

    var notificationModel = NotificationModel(
      collectionId: await Spdb.getCid() ?? '',
      title: "Permission Request",
      body: data.join('\n'),
      type: NotificationType.permissionRequest,
      createdAt: DateTime.now(),
      toFcms: receiverFcmIds,
      isChat: false,
      isPermissionRequest: true,
      payload: {},
    );
    if (receiverFcmIds.isNotEmpty) {
      PostNotificationService.sendNotification(model: notificationModel);
    }
  }

  static Future<String> permissionIdByName({required String id}) async {
    try {
      var cid = await Spdb.getCid();
      var doc = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc(id)
          .get();

      return doc.data()?["name"];
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> editPermission({
    required PermissionsStatus status,
    required String uid,
    required bool withSalary,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.permission.name}',
        uid,
        {
          'status': status.name,
          'withSalary': withSalary,
          'modified': DateTime.now().millisecondsSinceEpoch,
        },
        activity: "Permission status updated",
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw "Error editing permission: $e";
    }
  }

  static Future<WorkPermissionModel> getPermission({required String id}) async {
    try {
      var cid = await Spdb.getCid();

      var r = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc(id)
          .get();

      if (!r.exists) {
        throw "Permission not found";
      }

      final result = r.data()!;
      result["uid"] = r.id;

      return WorkPermissionModel.fromMap(result);
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> deletePermission({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      final ref = firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc(uid);

      final snap = await ref.get();
      if (!snap.exists) return;

      await TrashService.moveToTrash(
        docRef: ref,
        docData: snap.data()!,
        reason: 'permission_deleted',
      );

      var user = await Spdb.getUser();

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        ActivityLogModel(
          userData: user,
          activity: "Permission deleted",
          description: "Permission removed",
          collection:
              '${Collections.users.name}/$cid/${Collections.permission.name}',
          docId: uid,
        ).toMap(),
      );

      await ref.delete();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw "Delete permission failed: $e";
    }
  }

  static Future<void> approveOrRejectPermission({
    required PermissionsStatus status,
    required bool withSalary,
    required String uid,
  }) async {
    try {
      // 1️⃣ Get company & admin info
      var cid = await Spdb.getCid();
      var admin = await Spdb.getUser();
      var adminname = admin.name;

      if (cid == null) {
        throw Exception("Company not found. Please login again.");
      }

      // 2️⃣ Get permission document
      final docRef = firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc(uid);

      final permissionSnap = await docRef.get();

      if (!permissionSnap.exists) {
        throw Exception("Permission request not found");
      }

      final permissionData = permissionSnap.data()!;
      final userId = permissionData['userId'];
      // 3️⃣ Update permission status
      final now = DateTime.now();
      await docRef.update({
        'status': status.name.toString(),
        'withSalary': withSalary,
        'approvedBy': adminname,
        'approvedAt': now.millisecondsSinceEpoch,
        'modified': now.millisecondsSinceEpoch,
      });

      if (status == PermissionsStatus.approved && !withSalary) {
        await _deductSalaryForPermission(
          cid: cid,
          userId: userId,
          permissionId: uid,
          permissionData: permissionData,
        );
      }

      // 5️⃣ Send notification to employee
      await sendUserDecisionNotification(
        permissionId: uid,
        status: status,
        withSalary: withSalary,
      );

      await AttendanceService.updateAttendanceFromPermission(
        userId: userId,
        permissionId: uid,
        status: status,
      );
    } catch (e) {
      print("Permission approval error: $e");
      throw Exception("Failed to process permission: ${e.toString()}");
    }
  }

  static Future<void> _deductSalaryForPermission({
    required String cid,
    required String userId,
    required String permissionId,
    required Map<String, dynamic> permissionData,
  }) async {
    try {
      final from = DateTime.fromMillisecondsSinceEpoch(permissionData['from']);
      final to = DateTime.fromMillisecondsSinceEpoch(permissionData['to']);
      final duration = to.difference(from);
      final totalMinutes = duration.inMinutes;
      final totalHours = totalMinutes / 60.0;

      // Get employee salary info
      final userDoc = await firebase.users
          .doc(cid)
          .collection(Collections.employees.name)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("Employee profile not found");
      }

      final monthlySalary = (userDoc.data()?['monthlySalary'] ?? 0).toDouble();

      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateUtils.getDaysInMonth(now.year, now.month);
      // final monthEnd = DateTime(now.year, now.month, lastDay);

      int workingDays = 0;
      for (int i = 0; i < lastDay; i++) {
        final day = firstDay.add(Duration(days: i));
        if (day.weekday != DateTime.sunday) {
          workingDays++;
        }
      }

      final dailySalary = monthlySalary / workingDays;
      final hourlySalary = dailySalary / 8;
      final deductionAmount = totalHours * hourlySalary;

      await firebase.users
          .doc(cid)
          .collection(Collections.salaryLedger.name)
          .add({
            'userId': userId,
            'permissionId': permissionId,
            'type': 'permission_deduction',
            'hours': totalHours,
            'amount': deductionAmount,
            'description': 'Permission deduction',
            'month': now.year * 100 + now.month, // YYYYMM format
            'createdAt': now.millisecondsSinceEpoch,
            'createdBy': await Spdb.getUid(),
          });

      print(
        "✅ Salary deducted: ₹${deductionAmount.toStringAsFixed(2)} for $totalHours hours",
      );
    } catch (e) {
      print("Salary deduction error: $e");
      // Don't fail the approval if salary deduction fails
    }
  }

  /// ✅ FIXED: Proper Permission Decision Notification
  static Future<void> sendUserDecisionNotification({
    required String permissionId,
    required PermissionsStatus status,
    required bool withSalary,
  }) async {
    try {
      // 1️⃣ Get company ID
      final cid = await Spdb.getCid();
      if (cid == null) return;

      // 2️⃣ Get permission document
      final permissionSnap = await firebase.users
          .doc(cid)
          .collection(Collections.permission.name)
          .doc(permissionId)
          .get();

      if (!permissionSnap.exists) {
        print("Permission $permissionId not found");
        return;
      }

      final permissionData = permissionSnap.data()!;
      final userId = permissionData["userId"];
      if (userId == null || userId.isEmpty) return;

      // 3️⃣ Get user FCM token (from USERS collection)
      final userDoc = await firebase.users
          .doc(cid)
          .collection(Collections.users.name)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print("User document not found for $userId");
        return;
      }

      final fcmId = userDoc.data()?["fcmId"];
      if (fcmId == null || fcmId.isEmpty) {
        print("No FCM token found for user $userId");
        return;
      }

      // 4️⃣ Build notification message
      String statusMessage = status == PermissionsStatus.approved
          ? (withSalary ? "APPROVED WITH SALARY" : "APPROVED WITHOUT SALARY")
          : "REJECTED";

      String bodyMessage = status == PermissionsStatus.approved
          ? (withSalary
                ? "Your permission request has been approved with salary."
                : "Your permission request has been approved but salary will be deducted.")
          : "Your permission request has been rejected.";

      // 5️⃣ Create notification model
      var notificationModel = NotificationModel(
        collectionId: cid,
        title: "Permission $statusMessage",
        body: bodyMessage,
        type: NotificationType.permissionRequest,
        createdAt: DateTime.now(),
        toFcms: [fcmId],
        isChat: false,
        isPermissionRequest: true,
        payload: {
          'permissionId': permissionId,
          'status': status.name,
          'withSalary': withSalary,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // 6️⃣ Send notification
      await PostNotificationService.sendNotification(model: notificationModel);
      print("✅ Notification sent to user $userId for permission $permissionId");
    } catch (e) {
      print("❌ Notification error: $e");
      // Don't throw - approval should succeed even if notification fails
    }
  }

  static Future<List<WorkPermissionModel>> getTodayPermissions(
    String userUid,
  ) async {
    DateTime now = DateTime.now();

    DateTime start = DateTime(now.year, now.month, now.day);
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    var data = await firebase.users
        .doc(await Spdb.getCid())
        .collection(Collections.permission.name)
        .where("userUid", isEqualTo: userUid)
        .where("status", isEqualTo: PermissionsStatus.approved.name)
        .where("from", isLessThanOrEqualTo: end)
        .where("to", isGreaterThanOrEqualTo: start)
        .get();

    return data.docs.map((e) => WorkPermissionModel.fromMap(e.data())).toList();
  }
}
