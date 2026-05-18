import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import '/constants/constants.dart';
import '/firebase_options.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/app/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.setupFlutterNotifications();
    await NotificationService.instance.showNotification(message);
  } catch (e, st) {
    await ErrorService.recordError(e, st);
  }
}

Future<String> getToken() async {
  try {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.getAPNSToken();
    }
    String? fcm = await FirebaseMessaging.instance.getToken();
    return fcm ?? '';
  } catch (e, st) {
    await ErrorService.recordError(e, st);
    return '';
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initalize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      await _requestPermission();
      await setupFlutterNotifications();
      await _setupMessageHandlers();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> setupFlutterNotifications() async {
    try {
      if (_isFlutterLocalNotificationsInitialized) return;

      // Android setup
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Used for important notifications',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS setup
      final darwinNotificationCategories = [
        DarwinNotificationCategory(
          'REPLY_CATEGORY',
          actions: [
            DarwinNotificationAction.text(
              'REPLY_ACTION_KEY',
              'Reply',
              buttonTitle: 'Send',
              placeholder: 'Type your reply...',
            ),
          ],
        ),
      ];

      final initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: darwinNotificationCategories,
      );

      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) async {
          if (details.actionId == 'REPLY_ACTION_KEY') {
            final reply = details.input;
            final payload = convertPayload(details.payload ?? '{}');
            await _replyMessage(payload, reply ?? '');
          } else {
            _handleBackgroundMessage(convertPayload(details.payload ?? '{}'));
          }
        },
      );

      _isFlutterLocalNotificationsInitialized = true;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  final Map<String, List<Message>> _messageHistory = {};

  Future<void> showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;
      final type = data['type'];
      final chatId = data['chatId'];
      final senderName = notification?.title ?? 'Unknown';
      final messageText = notification?.body ?? data['body'] ?? 'New message';
      final senderImageUrl = data['senderImageUrl'];

      if (type == 'chat' && chatId != null) {
        String? avatarPath;
        if (senderImageUrl != null && senderImageUrl.isNotEmpty) {
          avatarPath = await _downloadAndMakeCircular(
            senderImageUrl,
            'sender_$chatId',
            size: 192,
          );
        }

        final groupKey = 'chat_$chatId';
        final bool isUserReply = data['isReply'] == 'true';

        final me = Person(name: 'You');

        final senderPerson = Person(
          name: isUserReply ? 'You' : senderName,
          icon: avatarPath != null
              ? BitmapFilePathAndroidIcon(avatarPath)
              : null,
        );

        final newMessage = Message(messageText, DateTime.now(), senderPerson);
        _messageHistory.putIfAbsent(groupKey, () => []);
        _messageHistory[groupKey]!.add(newMessage);

        final style = MessagingStyleInformation(
          me,
          messages: _messageHistory[groupKey] ?? [],
          conversationTitle: data['chatTitle'],
          groupConversation: false,
        );

        final notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            'Chat Messages',
            channelDescription: 'All chat messages',
            styleInformation: style,
            importance: Importance.max,
            priority: Priority.high,
            groupKey: groupKey,
            // largeIcon: avatarPath != null
            //     ? FilePathAndroidBitmap(avatarPath)
            //     : null,
            onlyAlertOnce: true,
            actions: [
              const AndroidNotificationAction(
                'REPLY_ACTION_KEY',
                'Quick Reply',
                showsUserInterface: true,
                allowGeneratedReplies: true,
                inputs: [
                  AndroidNotificationActionInput(label: 'Type reply...'),
                ],
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'REPLY_CATEGORY',
          ),
        );

        await _localNotifications.show(
          groupKey.hashCode,
          null,
          null,
          notificationDetails,
          payload: json.encode({...data, 'isReply': 'true'}),
        );
        return;
      }

      // Default fallback notification (unchanged)
      await _localNotifications.show(
        message.hashCode,
        notification?.title ?? data['title'] ?? 'Notification',
        notification?.body ?? data['body'] ?? 'You have a new message',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'General Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(data),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  Future<void> _replyMessage(
    Map<String, dynamic> message,
    String typedDataFromInput,
  ) async {
    try {
      ChatService.sendChatMessage(
        chatId: message["chatId"],
        message: typedDataFromInput,
      );

      showNotification(
        RemoteMessage(
          data: {
            "type": "chat",
            "chatId": message["chatId"],
            "chatTitle": message["chatTitle"],
            "isReply": "true",
          },
          notification: RemoteNotification(
            title: "You",
            body: typedDataFromInput,
          ),
        ),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  Future<void> _setupMessageHandlers() async {
    try {
      FirebaseMessaging.onMessage.listen(showNotification);

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleBackgroundMessage(message.data);
      });

      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage.data);
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  void _handleBackgroundMessage(Map<String, dynamic> message) async {
    var navigator = navigatorKey.currentState;
    if (navigator == null) return;
    bool isAdmin = await Spdb.isAdminLoggedIn();

    navigator.pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => MainScreen(isAdmin: isAdmin)),
      (route) => false,
    );

    await Future.delayed(const Duration(milliseconds: 200));

    if (message['type'] == 'chat') {
      var uid = await Spdb.getUid();
      var chat = json.decode(message['chat']);
      var chatModel = ChatModel.fromMap(chat["uid"], chat);
      navigator.push(
        CupertinoPageRoute(
          builder: (context) => ChatMessages(
            chat: chatModel,
            currentUser: uid ?? '',
            opponentUid: '',
            onOpenChat: null,
          ),
        ),
      );
    }

    await showDialog(
      context: navigator.context,
      builder: (context) =>
          ConfirmDialog(content: message.toString(), title: "Notification"),
    );
  }

  Map<String, dynamic> convertPayload(String payload) {
    try {
      return json.decode(payload);
    } catch (_) {
      return {};
    }
  }

  Future<String?> _downloadAndMakeCircular(
    String url,
    String name, {
    int size = 192,
    Duration ttl = const Duration(days: 7),
    bool forceRefresh = false,
  }) async {
    try {
      // create a safe cache filename using md5(url + name)
      final key = md5.convert(utf8.encode('$url|$name')).toString();
      final fileName = 'avatar_$key.png';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      // if cached file exists and not expired, return it
      if (!forceRefresh && await file.exists()) {
        try {
          final lastModified = await file.lastModified();
          final age = DateTime.now().difference(lastModified);
          if (age <= ttl) {
            // cache valid
            return file.path;
          }
          // otherwise we'll refresh below
        } catch (_) {
          // ignore lastModified errors and fallback to download
        }
      }

      // download the image bytes
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        // if there is a cached file (even stale), return it as fallback
        if (await file.exists()) return file.path;
        return null;
      }

      // decode the image
      final original = img.decodeImage(resp.bodyBytes);
      if (original == null) {
        if (await file.exists()) return file.path;
        return null;
      }

      // Resize & crop to square
      final square = img.copyResizeCropSquare(original, size: size);

      final int s = size;
      final masked = img.Image(width: s, height: s, numChannels: 4);

      final double cx = (s - 1) / 2.0;
      final double cy = (s - 1) / 2.0;
      final double radius = s / 2.0;

      for (var y = 0; y < s; y++) {
        for (var x = 0; x < s; x++) {
          final dx = x - cx;
          final dy = y - cy;
          final dist = sqrt(dx * dx + dy * dy);

          if (dist <= radius) {
            final pixel = square.getPixel(x, y);
            masked.setPixel(x, y, pixel);
          } else {
            masked.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }

      final pngBytes = img.encodePng(masked);

      // write to cache (overwrite if exists)
      await file.writeAsBytes(pngBytes, flush: true);

      return file.path;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint('Download/crop/cache error: $e\n$st');
      return null;
    }
  }

  Future<void> clearAvatarCache() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = Directory(dir.path).listSync();
      for (final f in files) {
        if (f is File &&
            f.path.endsWith('.png') &&
            f.path.contains('avatar_')) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint('_clearAvatarCache error: $e');
    }
  }
}

Future<void> deleteNotification(String uid) async {
  try {
    final FirebaseConfig firebase = FirebaseConfig();
    var cid = await Spdb.getCid();

    await firebase.users
        .doc(cid)
        .collection(Collections.notifications.name)
        .doc(uid)
        .delete();
  } catch (e, st) {
    await ErrorService.recordError(e, st);
    throw e.toString();
  }
}

Future<void> restoreNotification(NotificationModel item) async {
  try {
    final FirebaseConfig firebase = FirebaseConfig();
    final cid = await Spdb.getCid();

    await firebase.users
        .doc(cid)
        .collection(Collections.notifications.name)
        .doc(item.uid)
        .set(item.toMap()); // restore deleted notification
  } catch (e, st) {
    await ErrorService.recordError(e, st);
  }
}

Stream<int> getNotificationCount() async* {
  try {
    final firebase = FirebaseConfig();
    final cid = await Spdb.getCid();
    final uid = await Spdb.getUid();

    yield* firebase.users
        .doc(cid)
        .collection(Collections.notifications.name)
        .where('toUids', arrayContains: uid)
        .where('senderId', isNotEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  } catch (e, st) {
    ErrorService.recordError(e, st);
    rethrow;
  }
}
