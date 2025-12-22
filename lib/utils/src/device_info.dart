import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '/models/models.dart';
import '/services/services.dart';
import 'package:http/http.dart' as http;

class DeviceInfo {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  static Future<DeviceModel> getDeviceInfo({bool forDebug = false}) async {
    String? deviceId;
    String? deviceName;
    String? brand;
    String? model;
    String? platform;
    String? fcmId;

    try {
      if (kIsWeb) {
        // Web platform
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceId = webInfo.vendor ?? 'unknown';
        deviceName = webInfo.userAgent ?? 'unknown';
        brand = webInfo.browserName.name;
        model = 'Web Browser';
        platform = 'Web';
      } else if (Platform.isAndroid) {
        // Android
        final android = await deviceInfoPlugin.androidInfo;
        deviceId = android.id;
        deviceName = android.device;
        brand = android.brand;
        model = android.model;
        platform = 'Android';
        fcmId = await getToken();
      } else if (Platform.isIOS) {
        // iOS
        final ios = await deviceInfoPlugin.iosInfo;
        deviceId = ios.identifierForVendor ?? 'unknown';
        deviceName = ios.name;
        brand = ios.systemName;
        model = ios.model;
        platform = 'iOS';
        fcmId = await getToken();
      } else if (Platform.isWindows) {
        // Windows
        final windows = await deviceInfoPlugin.windowsInfo;
        deviceId = windows.deviceId;
        deviceName = windows.computerName;
        brand = 'Microsoft';
        model = windows.productName;
        platform = 'Microsoft';
      } else if (Platform.isLinux) {
        // Linux
        final linux = await deviceInfoPlugin.linuxInfo;
        deviceId = linux.machineId ?? 'unknown';
        deviceName = linux.name;
        brand = linux.prettyName;
        model = linux.version;
        platform = 'Linux';
      } else if (Platform.isMacOS) {
        // macOS
        final mac = await deviceInfoPlugin.macOsInfo;
        deviceId = mac.systemGUID ?? 'unknown';
        deviceName = mac.computerName;
        brand = 'Apple';
        model = mac.model;
        platform = 'macOS';
      } else {
        deviceId = 'unknown';
        deviceName = 'unknown';
        brand = 'unknown';
        model = 'unknown';
        platform = 'unknown';
      }
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      // Handle exceptions gracefully
      deviceId = 'error';
      deviceName = 'error';
      brand = 'error';
      model = e.toString();
    }

    if (forDebug) {
      return DeviceModel(
        deviceId: deviceId,
        deviceName: deviceName,
        brand: brand,
        model: model,
        platform: platform,
      );
    }

    return DeviceModel(
      deviceId: deviceId,
      deviceName: deviceName,
      brand: brand,
      model: model,
      platform: platform,
      lastLoginAt: DateTime.now(),
      fcmId: fcmId,
    );
  }
}

class LoginAlertDeviceInfo {
  static Future<Map<String, dynamic>> _getLocationAndIPAddress() async {
    try {
      final response = await http.get(Uri.parse("https://ipinfo.io/json"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "location": "${data['city']}, ${data['region']}, ${data['country']}",
          "ip_address": data['ip'],
        };
      } else {
        return {"location": "Unknown Location", "ip_address": "Unknown IP"};
      }
    } catch (e) {
      return {"location": "Unknown Location", "ip_address": "Unknown IP"};
    }
  }

  static Future<LoginAlertModel> getLoginAlertInfo() async {
    DeviceModel deviceInfo = await DeviceInfo.getDeviceInfo();
    String deviceString =
        "Device Name: ${deviceInfo.deviceName}, Brand: ${deviceInfo.brand}, Model: ${deviceInfo.model}, Platform: ${deviceInfo.platform}";

    Map<String, dynamic> locationData = await _getLocationAndIPAddress();

    return LoginAlertModel(
      ipAddress: locationData['ip_address'] ?? 'Unknown IP',
      location: locationData['location'] ?? 'Unknown Location',
      dateTime: DateTime.now(),
      device: deviceString,
    );
  }
}
