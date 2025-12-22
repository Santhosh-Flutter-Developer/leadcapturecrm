import 'dart:io';
import 'package:flutter/material.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/utils/utils.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  Widget? _homeWidget;

  bool get isLoggedIn => _isLoggedIn;
  Widget? get homeWidget => _homeWidget;

  Future<void> checkLoginStatus() async {
    var isLogin = await Spdb.checkLogin();
    // var vs = await Versions.checkVersion();

    // if (vs["status"]) {

    if (Platform.isWindows) {
      var isInstalled = await runtimeInstalled();
      if (!isInstalled) {
        _homeWidget = const RuntimeInstall();
        _isLoggedIn = true;
        notifyListeners();
        return;
      }
    }

    if (isLogin) {
      var isAdmin = await Spdb.isAdminLoggedIn();
      if (kIsDesktop) {
        _homeWidget = RouteScreen();
      } else {
        _homeWidget = MainScreen(isAdmin: isAdmin);
      }
    } else {
      _homeWidget = const Login();
    }
    // } else {
    //   _homeWidget = Update(uD: vs["vd"]);
    // }

    _isLoggedIn = true;
    notifyListeners();
  }
}

Future<bool> runtimeInstalled() async {
  try {
    final path = "C:\\Windows\\System32\\vcruntime140.dll";
    return File(path).existsSync();
  } catch (e) {
    return false;
  }
}
