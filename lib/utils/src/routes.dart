import 'package:flutter/cupertino.dart';

class Navigate {
  static void route(BuildContext context, Widget widget) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) {
      return widget;
    }));
  }

  static void routeReplace(BuildContext context, Widget widget) {
    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) {
      return widget;
    }));
  }
}
