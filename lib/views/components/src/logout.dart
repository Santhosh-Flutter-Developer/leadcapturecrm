import 'package:flutter/material.dart';
import '/app/app.dart';
import '/services/services.dart';
import '/views/views.dart';

Future<void> forceLogout() async {
  try {
    await AuthService.removeCurrentDeviceFcm();
    Spdb.clearDb();
    CacheService().clearAllBoxes();
    NotificationService.instance.clearAvatarCache();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  } catch (e, st) {
    await ErrorService.recordError(e, st);
    debugPrint("${e.toString()}, ${st.toString()}");
    debugPrint('Logout failed: $e');
  }
}

Future<void> logout(context) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => const ConfirmDialog(
      title: "Logout",
      content: "Are you sure want to logout?",
    ),
  ).then((value) async {
    if (value != null && value) {
      futureLoading(context);
      await AuthService.removeCurrentDeviceFcm();
      Spdb.clearDb();
      CacheService().clearAllBoxes();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
      FlushBar.show(context, "Logout Successfully", isSuccess: true);
    }
  });
}
