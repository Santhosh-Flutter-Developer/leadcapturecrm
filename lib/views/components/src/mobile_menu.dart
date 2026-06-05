import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/views/screens/chat/listing/bloc/chat_bloc.dart';
import 'package:leadcapture/views/screens/download/download_history.dart';
import 'package:url_launcher/url_launcher.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import '/theme/theme.dart';
import '/constants/constants.dart';

class MobileMenu extends StatefulWidget {
  const MobileMenu({super.key});

  @override
  State<MobileMenu> createState() => _MobileMenuState();
}

class _MobileMenuState extends State<MobileMenu> {
  EmployeeModel? _employeeModel;
  AdminModel? _adminModel;
  RoleModel? _roleModel;
  UserDataModel? _userDataModel;
  late Future _future;
  VersionModel? _versionModel;

  @override
  void initState() {
    super.initState();
    _future = _getUser();
    _versionModel = VersionService.version;
  }

  Future<void> _getUser() async {
    final (user) = await Spdb.getUser();

    if (mounted) {
      if (user.userType == UserType.employee) {
        _employeeModel = await EmployeeService.getEmployee(uid: user.uid);
      } else {
        _adminModel = await AdminService.getAdmin(uid: user.uid);
      }

      _userDataModel = user;

      setState(() {});
    }
    if (_employeeModel != null && _employeeModel?.role != null) {
      _roleModel = await RoleService.getRole(uid: _employeeModel?.role ?? '');
    }
  }

  void _openClientSection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.user),
                title: const Text("Contacts"),
                onTap: () {
                  Navigator.pop(context);
                  Navigate.route(
                    context,
                    const ClientsListing(section: ClientSection.contacts),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.building),
                title: const Text("Company"),
                onTap: () {
                  Navigator.pop(context);
                  Navigate.route(
                    context,
                    const ClientCompanyListing(section: ClientSection.company),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 8),
                    Text(
                      "Company",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    _buildListTile(
                      icon: Iconsax.activity,
                      title: 'Feed',
                      onTap: () => Navigate.route(
                        context,
                        BlocProvider(
                          create: (context) => FeedBloc(),
                          child: FeedListing(),
                        ),
                      ),
                    ),
                    _buildListTile(
                      icon: Iconsax.message,
                      title: 'Chat',
                      onTap: () => Navigate.route(
                        context,
                        BlocProvider(
                          create: (context) => ChatBloc(),
                          child: ChatListing(
                            currentUserUid: _userDataModel?.uid ?? '',
                          ),
                        ),
                      ),
                    ),
                    _buildListTile(
                      icon: Iconsax.calendar_1,
                      title: 'Calendar',
                      onTap: () => Navigate.route(
                        context,
                        const CalendarEventScreen(showAppbar: true),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_adminModel != null ||
                        (
                        // (_roleModel?.permissions
                        //           .where((e) => e.page == "Admin")
                        //           .isNotEmpty ??
                        //       false) ||
                        //   _adminModel != null ||
                        (_roleModel?.permissions
                                    .where((e) => e.page == "Role")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Designation")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Department")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Sub Department")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Employees")
                                    .isNotEmpty ??
                                false))) ...[
                      Text(
                        "Creation",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      // if (_adminModel != null ||
                      //     (_roleModel?.permissions
                      //             .where((e) => e.page == "Admin")
                      //             .isNotEmpty ??
                      //         false))
                      //   _buildListTile(
                      //     icon: Iconsax.user,
                      //     title: 'Admin',
                      //     onTap: () =>
                      //         Navigate.route(context, const AdminListing()),
                      //   ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Role")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.user_square,
                          title: 'Role',
                          onTap: () =>
                              Navigate.route(context, const RolesListing()),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Designation")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.tick_circle,
                          title: 'Designation',
                          onTap: () => Navigate.route(
                            context,
                            const DesignationListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Department")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.building,
                          title: 'Department',
                          onTap: () => Navigate.route(
                            context,
                            const DepartmentListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Sub Department")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.building_3,
                          title: 'Sub Department',
                          onTap: () => Navigate.route(
                            context,
                            const SubDepartmentListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Employees")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.security_user,
                          title: 'Employees',
                          onTap: () =>
                              Navigate.route(context, const EmployeeListing()),
                        ),
                    ],
                    SizedBox(height: 8),
                    if (_adminModel != null ||
                        ((_roleModel?.permissions
                                    .where((e) => e.page == "Clients")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Projects")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Tasks")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Lead Category")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Lead Status")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Lead Source")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Lead Priority")
                                    .isNotEmpty ??
                                false) ||
                            (_roleModel?.permissions
                                    .where((e) => e.page == "Deal Status")
                                    .isNotEmpty ??
                                false))) ...[
                      Text(
                        "CRM",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Leads")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.graph,
                          title: 'Leads',
                          onTap: () =>
                              Navigate.route(context, const LeadsListing()),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Lead Category")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.category,
                          title: 'Lead Category',
                          onTap: () => Navigate.route(
                            context,
                            const LeadCategoryListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Lead Status")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.link_circle,
                          title: 'Lead Status',
                          onTap: () => Navigate.route(
                            context,
                            const LeadStatusListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Lead Source")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.share,
                          title: 'Lead Source',
                          onTap: () => Navigate.route(
                            context,
                            const LeadSourceListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Lead Priority")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.flag,
                          title: 'Lead Priority',
                          onTap: () => Navigate.route(
                            context,
                            const LeadPriorityListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Deals")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.grid_lock,
                          title: 'Deals',
                          onTap: () =>
                              Navigate.route(context, const DealsListing()),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Deal Status")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.activity,
                          title: 'Deal Status',
                          onTap: () => Navigate.route(
                            context,
                            const DealStatusListing(),
                          ),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Tasks")
                                  .isNotEmpty ??
                              false))
                        SizedBox(height: 8),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Clients")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.people,
                          title: 'Clients',
                          onTap: () => _openClientSection(context),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Projects")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.airdrop,
                          title: 'Projects',
                          onTap: () =>
                              Navigate.route(context, const ProjectsListing()),
                        ),
                      if (_adminModel != null ||
                          (_roleModel?.permissions
                                  .where((e) => e.page == "Tasks")
                                  .isNotEmpty ??
                              false))
                        _buildListTile(
                          icon: Iconsax.check,
                          title: 'Tasks',
                          onTap: () =>
                              Navigate.route(context, const TasksListing()),
                        ),
                      SizedBox(height: 8),
                    ],
                    if (_adminModel != null) ...[
                      Text(
                        "System",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      _buildListTile(
                        icon: Iconsax.login,
                        title: 'Login Logs',
                        onTap: () => Navigate.route(
                          context,
                          LoginLogsListing(showAppbar: true),
                        ),
                      ),
                      _buildListTile(
                        icon: Iconsax.activity,
                        title: 'Activity Logs',
                        onTap: () => Navigate.route(
                          context,
                          ActivityLogsListing(showAppbar: true),
                        ),
                      ),
                      _buildListTile(
                        icon: Iconsax.cloud,
                        title: 'Backups',
                        onTap: () => Navigate.route(context, BackupListing()),
                      ),
                      SizedBox(height: 8),
                    ],
                    _buildListTile(
                      icon: Iconsax.document_download,
                      title: 'Download history',
                      onTap: () => Navigate.route(
                        context,
                        DownloadHistory(showAppbar: true),
                      ),
                    ),

                    // Text(
                    //   "Payroll",
                    //   style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    //     color: Theme.of(context).colorScheme.outline,
                    //   ),
                    // ),
                    // _buildListTile(
                    //   icon: Iconsax.timer_1,
                    //   title: 'Work Time',
                    //   onTap: () => Navigate.route(
                    //     context,
                    //     _adminModel != null
                    //         ? const DashboardWorktime()
                    //         : const WorktimeCreate(),
                    //   ),
                    // ),

                    // _buildListTile(
                    //   icon: Iconsax.clipboard_tick,
                    //   title: 'Attendance Ledger',
                    //   onTap: () => Navigate.route(context, Attendance()),
                    // ),

                    // _buildListTile(
                    //   icon: Iconsax.security_user,
                    //   title: 'Permissions',
                    //   onTap: () => Navigate.route(
                    //     context,
                    //     _adminModel != null
                    //         ? const PermissionRequestsListing()
                    //         : const PermissionListing(),
                    //   ),
                    // ),

                    // _buildListTile(
                    //   icon: Iconsax.wallet_3,
                    //   title: 'Salary Ledger',
                    //   onTap: () =>
                    //       Navigate.route(context, const SalaryLedgerList()),
                    // ),
                    Text(
                      "Others",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    _buildListTile(
                      icon: Iconsax.recovery_convert,
                      title: 'Sync',
                      onTap: () async {
                        await CacheService.syncAllCollections();
                        var result = await AuthService.refreshLogin();
                        if (result['userData'] != null) {
                          var data = result["userData"];
                          var uid = result["uid"];

                          EmployeeModel emp = EmployeeModel.fromMap(uid, data);
                          await Spdb.setEmployeeLogin(
                            model: emp,
                            cid: result["collectionId"],
                            logoUrl: result["companyLogo"],
                          );

                          RoleModel role = await RoleService.getRole(
                            uid: emp.role,
                          );
                          await PermissionService.savePermissions(
                            role.permissions,
                          );
                        }
                        FlushBar.show(context, 'Synced Successfully');
                      },
                      showTrailing: false,
                    ),
                    _buildListTile(
                      icon: Iconsax.trash,
                      title: 'Trash',
                      onTap: () => Navigate.route(context, const TrashScreen()),
                      showTrailing: false,
                    ),
                    _buildListTile(
                      icon: Iconsax.setting_2,
                      title: 'Settings',
                      onTap: () => Navigate.route(context, const Settings()),
                      showTrailing: false,
                    ),
                    _buildListTile(
                      icon: Iconsax.command,
                      title: 'Developer Area',
                      onTap: () => Navigate.route(context, const Developer()),
                      showTrailing: false,
                    ),
                    _buildListTile(
                      icon: Iconsax.logout,
                      title: 'Logout',
                      onTap: () => logout(context),
                      showTrailing: false,
                      isLogout: true,
                    ),
                    _buildListTile(
                      icon: Iconsax.mobile,
                      title: 'App Version',
                      subtitle: AppPackageInfo.version,
                      onTap: () {},
                      showTrailing: false,
                    ),
                    if (_versionModel != null &&
                        (_versionModel?.isUpdateNeed ?? false))
                      _buildAppUpdateContainer(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showTrailing = true,
    bool isLogout = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isLogout
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isLogout
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: isLogout
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
              : null,
          onTap: onTap,
          trailing: showTrailing ? const Icon(Iconsax.arrow_right_3) : null,
        ),
        Divider(indent: 0, endIndent: 0, height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildHeader() {
    // Use the non-null _employeeModel
    final employee = _employeeModel;
    final admin = _adminModel;

    return InkWell(
      onTap: () => Navigate.route(context, const Profile()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userDataModel != null)
              UserAvatar(userData: _userDataModel!, size: 40),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  employee?.name ?? admin?.name ?? 'User',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  employee != null
                      ? (CacheService.designationByUid(
                              employee.designation,
                            )?.name) ??
                            ''
                      : "Administartor",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUpdateContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90E2).withValues(alpha: 0.18),
            const Color(0xFF7F53AC).withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Update Available (v${_versionModel?.version})",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222B45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "A newer version of the app is available. Update now for better performance, features and stability.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        if (Platform.isAndroid) {
                          Navigate.route(context, AndroidUpdate());
                        } else {
                          Uri url = Uri.parse(_versionModel?.url ?? '');
                          if (await canLaunchUrl(url)) {
                            launchUrl(url);
                          }
                        }
                      } catch (e, st) {
                        FlushBar.show(context, e.toString(), isSuccess: false);
                        await ErrorService.recordError(e, st);
                      }
                    },
                    child: Text(
                      "Update Now",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
