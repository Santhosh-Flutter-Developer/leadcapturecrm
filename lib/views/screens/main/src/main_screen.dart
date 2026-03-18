import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/views/screens/attendance/attendance.dart';
import 'package:leadcapture/views/screens/download/bloc/download_bloc.dart';
import 'package:leadcapture/views/screens/download/download_history.dart';
import 'package:leadcapture/views/screens/permission/src/permission_listing.dart';
import 'package:leadcapture/views/screens/permission/src/permission_requests/src/permission_requests_listing.dart';
import 'package:leadcapture/views/screens/salary_ledger/salary_ledger_listing.dart';
import 'package:leadcapture/views/screens/worktime/src/index_worktime.dart';
import 'package:leadcapture/views/screens/worktime/src/worktime_create.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import '/services/services.dart';
part 'mobile_main_screen.dart';
part 'desktop_main_screen.dart';

class MainScreen extends StatelessWidget {
  final bool isAdmin;
  final String? selectedMenu;
  const MainScreen({super.key, required this.isAdmin, this.selectedMenu});

  @override
  Widget build(BuildContext context) {
    if (kIsMobile) {
      return MobileMainScreen(isAdmin: isAdmin);
    } else {
      return DesktopMainScreen(isAdmin: isAdmin, selectedMenu: selectedMenu);
    }
  }
}
