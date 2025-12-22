import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '/services/services.dart';

class AudioRecorder {
  static const _channel = MethodChannel('com.srisoftwarez.audio_recorder');

  static Future<bool> requestMicPermission() async {
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      return status.isGranted;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      return false;
    }
  }

  static Future<void> startRecording() async {
    try {
      if (await requestMicPermission()) {
        await _channel.invokeMethod('startRecording');
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final String? path = await _channel.invokeMethod('stopRecording');
      return path;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
    return null;
  }
}
