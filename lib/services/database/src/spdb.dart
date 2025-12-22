import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/models/models.dart';

class Spdb {
  static Future<SharedPreferences> _connect() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> forceLogout() async {
    try {
      final cn = await _connect();
      await cn.clear();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  static Future<void> setEmployeeLogin({
    required EmployeeModel model,
    required String cid,
  }) async {
    try {
      final cn = await _connect();

      cn.setString("cid", cid);
      cn.setBool("employee_login", true);
      cn.setBool("admin_login", false);

      var map = model.toMap();
      map["uid"] = model.uid;
      cn.setString("employee", jsonEncode(map));
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  static Future<bool> isEmployeeLoggedIn() async {
    final cn = await _connect();
    return cn.getBool("employee_login") ?? false;
  }

  static Future<EmployeeModel?> getEmployee() async {
    try {
      final cn = await _connect();
      final raw = cn.getString("employee");

      if (raw == null) return null;

      final data = jsonDecode(raw);

      return EmployeeModel.fromMap(data["uid"], data);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      return null;
    }
  }

  static Future<bool> checkLogin() async {
    final cn = await _connect();
    return (cn.getBool("employee_login") ?? false) ||
        (cn.getBool("admin_login") ?? false);
  }

  static Future<UserDataModel> getUser() async {
    try {
      final cn = await _connect();
      final raw = cn.getString('employee') ?? cn.getString('admin');
      if (raw == null) return UserDataModel.fromEmptyMap();

      final data = jsonDecode(raw);
      EmployeeModel? employeeModel;
      AdminModel? adminModel;
      if (cn.getBool("admin_login") == true) {
        adminModel = AdminModel.fromMap(data["uid"], data);
      } else {
        employeeModel = EmployeeModel.fromMap(data["uid"], data);
      }

      UserDataModel userDataModel = UserDataModel(
        uid: employeeModel?.uid ?? adminModel?.uid ?? '',
        name: employeeModel?.name ?? adminModel?.name ?? '',
        profilePic:
            employeeModel?.profileImageUrl ?? adminModel?.profileImageUrl ?? '',
        desc: employeeModel?.designation ?? adminModel?.email ?? '',
        userType: employeeModel != null
            ? UserType.employee
            : adminModel != null
            ? UserType.admin
            : UserType.employee,
      );

      return userDataModel;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      return UserDataModel.fromEmptyMap();
    }
  }

  static Future<String?> getCid() async {
    final cn = await _connect();
    return cn.getString('cid');
  }

  static Future<String?> getUid() async {
    final cn = await _connect();

    if (cn.getBool("admin_login") == true) {
      final raw = cn.getString("admin");
      if (raw != null) {
        Map<String, dynamic> data = json.decode(raw);
        return data['uid'];
      }
    }

    if (cn.getBool("employee_login") == true) {
      final raw = cn.getString("employee");
      if (raw != null) {
        Map<String, dynamic> data = json.decode(raw);
        return data['uid'];
      }
    }

    return null;
  }

  static Future<void> setAdminLogin({
    required AdminModel model,
    required String cid,
  }) async {
    try {
      final cn = await _connect();

      cn.setString("cid", cid);
      cn.setBool("admin_login", true);
      cn.setBool("employee_login", false);

      var map = model.toMap();
      map["uid"] = model.uid;

      cn.setString("admin", jsonEncode(map));
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  static Future<bool> isAdminLoggedIn() async {
    final cn = await _connect();
    return cn.getBool("admin_login") ?? false;
  }

  static Future<AdminModel?> getAdmin() async {
    try {
      final cn = await _connect();
      final raw = cn.getString("admin");

      final data = jsonDecode(raw ?? '{}');
      return AdminModel.fromMap(data["uid"], data);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      return null;
    }
  }

  static Future<void> logoutAdmin() async {
    try {
      final cn = await _connect();
      await cn.remove("admin");
      await cn.setBool("admin_login", false);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  Future<void> logoutEmployee() async {
    try {
      final cn = await _connect();
      await cn.remove("employee");
      await cn.setBool("employee_login", false);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  static Future<void> clearDb() async {
    try {
      final cn = await _connect();
      await cn.clear();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  static Future<void> saveSettings(String id) async {
    final prefs = await _connect();
    await prefs.setString('settingsDocId', id);
  }

  static Future<String?> getSettings() async {
    final prefs = await _connect();
    return prefs.getString('settingsDocId');
  }
}
