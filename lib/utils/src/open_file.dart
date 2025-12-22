import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart' as of;
import '/services/services.dart';
import '/views/views.dart';

void openfile(String path, BuildContext context) async {
  try {
    await of.OpenFile.open(path);
  } catch (e, st) {
    debugPrint("${e.toString()}, ${st.toString()}");
    await ErrorService.recordError(e, st);
    FlushBar.show(context, e.toString(), isSuccess: false);
  }
}
