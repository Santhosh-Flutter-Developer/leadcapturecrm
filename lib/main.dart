import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';
import '/firebase_options.dart';
import '/app/app.dart';
import '/services/services.dart';
import '/utils/utils.dart';

class LifecycleHandler extends WidgetsBindingObserver {
  final String uid;

  LifecycleHandler(this.uid);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (uid.isEmpty) return;

    switch (state) {
      case AppLifecycleState.resumed:
        UserStatusService.setOnline(uid);
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        UserStatusService.setOffline(uid);
        break;
      default:
        UserStatusService.setOffline(uid);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kIsMobile) {
    NotificationService.instance.initalize();
  } else if (kIsDesktop) {
    await localNotifier.setup(appName: 'AAATP');
    FirestoreNotificationListener.listenForNotifications();

    // FlutterWindowClose.setWindowShouldCloseHandler(() async {
    //   // default allow, real handling happens inside App via navigatorKey
    //   return true;
    // });
  }

  await AppPackageInfo.init();
  await CacheService().init();
  await VersionService.init();
  await Spdb.loadPanelSettings();

  final uid = await Spdb.getUid();
  if (uid != null && uid.isNotEmpty) {
    WidgetsBinding.instance.addObserver(LifecycleHandler(uid));
    UserStatusService.setOnline(uid);
  }

  runApp(const App());
}
