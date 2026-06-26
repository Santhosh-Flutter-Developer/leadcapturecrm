// ─────────────────────────────────────────────────────────────────────────────
// desktop_notifier_native.dart  — NEW FILE
// Used on native desktop platforms via conditional import in main.dart.
// Wraps the original local_notifier setup so the import never reaches web.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:local_notifier/local_notifier.dart';
import '/services/firebase/src/windows_notification_service.dart';

/// Sets up local_notifier and starts the Firestore notification listener.
/// Called only from native desktop platforms (Windows / macOS / Linux).
Future<void> setupDesktopNotifier() async {
  await localNotifier.setup(appName: 'Lead Capture');
  FirestoreNotificationListener.listenForNotifications();
}
