import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';
import '/services/services.dart';
import '/app/app.dart';
import '/constants/constants.dart';
import '/views/views.dart';

class FirestoreNotificationListener {
  static final FirebaseConfig firebase = FirebaseConfig();
  static String? lastNotificationId;

  static void listenForNotifications() async {
    var cid = await Spdb.getCid();
    var uid = await Spdb.getUid();

    if (uid != null && cid != null) {
      firebase.users
          .doc(cid)
          .collection(Collections.notifications.name)
          .where('toUids', arrayContains: uid.trim())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((querySnapshot) {
            for (var change in querySnapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                var data = change.doc.data();

                DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
                  data?['createdAt'],
                );

                if (DateTime.now().difference(createdAt).inSeconds < 30) {
                  String docId = change.doc.id; // Unique ID of the document

                  // Skip past notifications
                  if (lastNotificationId != null &&
                      docId == lastNotificationId) {
                    continue;
                  }

                  lastNotificationId = docId; // Update last seen notification

                  String title = data?['title'] ?? 'New Notification';
                  String message = data?['message'] ?? 'You have a new message';
                  String senderId = data?['senderId'] ?? '';

                  Map<String, dynamic> payload = data?['payload'] != null
                      ? data!['payload']
                      : {};

                  if (senderId != uid) {
                    LocalNotification notification = LocalNotification(
                      title: title,
                      body: message,
                    );

                    notification.onClick = () async {
                      await windowManager.focus();
                      await windowManager.show();

                      var navigator = navigatorKey.currentState;
                      if (navigator == null) return;
                      bool isAdmin = await Spdb.isAdminLoggedIn();

                      navigator.pushAndRemoveUntil(
                        CupertinoPageRoute(
                          builder: (_) => MainScreen(isAdmin: isAdmin),
                        ),
                        (route) => false,
                      );
                      if (payload.containsKey('type')) {
                        // payload['type'] = payload['type'].toString().trim();
                        // if (payload['type'] == 'task') {
                        //   navigator.push(
                        //     CupertinoPageRoute(
                        //       builder: (context) =>
                        //           TaskView(uid: payload['taskId']),
                        //     ),
                        //   );
                        // }
                      }
                    };

                    notification.show();
                  }
                }
              }
            }
          });
    }
  }

  static Future<void> sendTestNotification() async {
    try {
      LocalNotification notification = LocalNotification(
        title: "Test Notification",
        body: "This is a test notification.",
      );

      notification.onClick = () async {
        await windowManager.focus();
        await windowManager.show();

        var navigator = navigatorKey.currentState;
        if (navigator == null) return;
        bool isAdmin = await Spdb.isAdminLoggedIn();

        navigator.pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => MainScreen(isAdmin: isAdmin)),
          (route) => false,
        );
      };

      notification.show();
    } catch (e) {
      throw 'Error sending test notification: $e';
    }
  }
}
