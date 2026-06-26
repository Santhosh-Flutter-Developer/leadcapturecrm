// ─────────────────────────────────────────────────────────────────────────────
// main.dart
// CHANGED:
//   • Removed `import 'package:local_notifier/local_notifier.dart'`
//     (not web-compatible — crashes on web at compile time)
//   • Added conditional import for DesktopNotificationSetup stub/native
//   • Added kIsWeb branch: initialises web FCM push notifications
//   • LifecycleHandler guarded behind !kIsWeb (AppLifecycle API is
//     not fully supported on web)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/firebase_options.dart';
import '/app/app.dart';
import '/services/services.dart';
import '/utils/utils.dart';

// Conditional import for desktop-only notification setup.
// On web → stub (does nothing). On native → real local_notifier setup.
import 'services/firebase/src/desktop_notifier_stub.dart'
    if (dart.library.io) 'services/firebase/src/desktop_notifier_native.dart';

// ─── Lifecycle handler (online / offline status) ─────────────────────────────
// Only registered on non-web platforms where AppLifecycle works reliably.
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

// ─── Entry point ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kIsWeb) {
    // ── Web: use Firebase Messaging web push (VAPID) ──────────────────────
    // NotificationService.instance.initalize() uses flutter_local_notifications
    // which is NOT web-compatible. On web we call initializeForWeb() instead,
    // which requests browser permission and obtains the FCM web token.
    await NotificationService.instance.initializeForWeb();
  } else if (kIsMobile) {
    // ── Mobile (Android / iOS) ────────────────────────────────────────────
    NotificationService.instance.initalize();
  } else if (kIsDesktop) {
    // ── Desktop (Windows / macOS / Linux) ────────────────────────────────
    // setupDesktopNotifier() is the conditional import:
    //   • web / unsupported  → stub (no-op)
    //   • native             → localNotifier.setup() + listenForNotifications()
    await setupDesktopNotifier();
  }

  await AppPackageInfo.init();
  await CacheService().init();
  await VersionService.init();
  await Spdb.loadPanelSettings();
  await Spdb.loadPayrollSettings();

  // Register lifecycle observer only on native (web doesn't need it and
  // AppLifecycle.paused / detached don't fire reliably in browsers).
  if (!kIsWeb) {
    final uid = await Spdb.getUid();
    if (uid != null && uid.isNotEmpty) {
      WidgetsBinding.instance.addObserver(LifecycleHandler(uid));
      UserStatusService.setOnline(uid);
    }
  }

  runApp(const App());
}
