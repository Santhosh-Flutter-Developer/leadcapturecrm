import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import '/constants/constants.dart';
import '/services/services.dart';
import '/models/models.dart';

class PostNotificationService {
  static FirebaseConfig firebase = FirebaseConfig();

  static Future<String?> _getAccessToken() async {
    try {
      final tokenDoc = await firebase.system.doc('serviceToken').get();

      if (tokenDoc.exists) {
        final data = tokenDoc.data()!;
        final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry']);
        if (DateTime.now().isBefore(
          expiry.subtract(const Duration(minutes: 5)),
        )) {
          debugPrint("Using cached token from Firestore");
          return data['token'];
        }
      }

      var serviceAccountDoc = await firebase.system.doc('serviceAccount').get();
      var serviceAccount = serviceAccountDoc.data()!['account'];

      // otherwise generate new one
      final serviceAccountJson = json.decode(serviceAccount);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final credentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final client = await auth.clientViaServiceAccount(credentials, scopes);

      final newToken = client.credentials.accessToken.data;
      final expiry = client.credentials.accessToken.expiry;
      client.close();

      await firebase.system.doc('serviceToken').set({
        'token': newToken,
        'expiry': expiry.millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint("New token generated and saved");
      return newToken;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Token error: $e\n$st");
      return null;
    }
  }

  static Future<void> sendNotification({
    required NotificationModel model,
  }) async {
    try {
      final String? serverKey = await _getAccessToken();
      if (serverKey == null) return;

      String endpointFirebaseCloudMessaging =
          "https://fcm.googleapis.com/v1/projects/leadcapture-79a43/messages:send";
      if (model.toFcms.isNotEmpty) {
        for (var element in model.toFcms) {
          final Map<String, dynamic> message = {
            "message": {
              "notification": {
                "title": model.title,
                "body": model.message,
                // if (model.img != null) "image": model.img,
              },
              "android": {
                "priority": "high",
                "notification": {
                  "channel_id": "high_importance_channel",
                  "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
                // if (model.img != null)
                //   "notification": {
                //     "image": model.img,
                //   },
              },
              "apns": {
                "headers": {"apns-priority": "10"},
                "payload": {
                  "aps": {
                    "category": "FLUTTER_NOTIFICATION_CATEGORY_DEFAULT",
                    "alert": {"title": model.title, "body": model.message},
                    // if (model.img != null) "mutable-content": 1,
                  },
                  // if (model.img != null) "mediaUrl": model.img,
                },
              },
              "token": element,
              "data": model.payload,
            },
          };

          final http.Response response = await http.post(
            Uri.parse(endpointFirebaseCloudMessaging),
            headers: {
              'Authorization': 'Bearer $serverKey',
              'Content-Type': 'application/json',
            },
            body: json.encode(message),
          );

          if (response.statusCode == 200) {
            debugPrint(response.body);
          }
        }
      }

      var cid = await Spdb.getCid();

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.notifications.name}',
        model.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }
}
