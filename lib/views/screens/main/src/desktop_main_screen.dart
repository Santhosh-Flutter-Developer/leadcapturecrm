part of 'main_screen.dart';

class DesktopMainScreen extends StatefulWidget {
  final bool isAdmin;
  final String? selectedMenu;
  const DesktopMainScreen({
    super.key,
    required this.isAdmin,
    this.selectedMenu,
  });

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  late Future _future;
  late String _currentUserUid;
  final List<UserDataModel> _users = [];

  final items = [
    {"icon": Iconsax.message, "label": "Messenger"},
    {"icon": Iconsax.graph, "label": "Leads"},
    {"icon": Iconsax.grid_lock, "label": "Deals"},
    {"icon": Iconsax.menu, "label": "Menu"},
  ];

  @override
  void initState() {
    _future = _init();
    _selectedMenu = widget.selectedMenu ?? 'Dashboard';
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _users.clear();
      _currentUserUid = await Spdb.getUid() ?? '';

      var employees = await EmployeeService.getAllEmployees(
        excludeCurrentUser: true,
      );
      _users.addAll(
        employees
            .map(
              (e) => UserDataModel(
                name: e.name,
                uid: e.uid ?? '',
                userType: UserType.employee,
                profilePic: e.profileImageUrl,
              ),
            )
            .toList(),
      );
      var admins = await AdminService.getAllAdmins(excludeCurrentUser: true);
      _users.addAll(
        admins
            .map(
              (e) => UserDataModel(
                name: e.name,
                uid: e.uid ?? '',
                userType: UserType.admin,
                profilePic: e.profileImageUrl,
              ),
            )
            .toList(),
      );

      _users.sort((a, b) => a.name.compareTo(b.name));
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  String _selectedMenu = 'Dashboard';

  void _onMenuItemSelected(String title) async {
    setState(() {
      _selectedMenu = title;
    });
    RecentActivityService().addActivity(page: _selectedMenu);
  }

  Widget _buildMainContent() {
    switch (_selectedMenu) {
      case 'Dashboard':
        return BlocProvider(
          create: (context) => DashboardBloc(
            dashboard: DashboardService(),
            userId: _currentUserUid,
            isAdmin: widget.isAdmin,
          )..add(LoadDashboardEvent(filter: '')),
          child: Dashboard(isAdmin: widget.isAdmin),
        );
      case 'Admin':
        return const AdminListing();
      case 'Role':
        return const RolesListing();
      case 'Designation':
        return const DesignationListing();
      case 'Department':
        return const DepartmentListing();
      case 'Sub Department':
        return const SubDepartmentListing();
      case 'Employees':
        return const EmployeeListing();
      case 'Lead Category':
        return const LeadCategoryListing();
      case 'Lead Status':
        return const LeadStatusListing();
      case 'Lead Source':
        return const LeadSourceListing();
      case 'Deal Status':
        return const DealStatusListing();
      case 'Leads':
        return const LeadsListing();
      case 'Deals':
        return const DealsListing();
      case 'Contact':
        return const ClientsListing(section: ClientSection.contacts);
      case 'Company':
        return const ClientsListing(section: ClientSection.company);
      case 'Projects':
        return const ProjectsListing();
      case 'Tasks':
        return const TasksListing();
      case 'Chats':
        return ChatListing(currentUserUid: _currentUserUid);
      case 'Calendar':
        return const CalendarEventScreen();
      case 'Developer Area':
        return const Developer(showAppbar: false);
      case 'Settings':
        return Settings(showAppbar: false);
      case 'Login Logs':
        return const LoginLogsListing(showAppbar: false);
      case 'Activity Logs':
        return const ActivityLogsListing(showAppbar: false);
      case 'Feed':
        return BlocProvider(
          create: (context) => FeedBloc(),
          child: FeedListing(),
        );
      default:
        return Center(
          child: Text(
            "Content for $_selectedMenu",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
    }
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
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            );
          }
          return Row(
            children: [
              DesktopSidebar(
                selectedMenu: _selectedMenu,
                onMenuSelected: _onMenuItemSelected,
                isAdmin: widget.isAdmin,
              ),
              Expanded(
                child: Column(
                  children: [
                    Header(selectedMenu: _selectedMenu),
                    Expanded(child: _buildMainContent()),
                  ],
                ),
              ),
              if (_selectedMenu != 'Chats') _buildGlassNavigationRail(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassNavigationRail() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: ListView.separated(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      var userData = _users[index];
                      return Center(
                        child: UserAvatar(userData: userData, size: 30),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                  ),
                ),
              ),
              _buildRailItem(icon: Icons.help, label: 'Help'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRailItem({required IconData icon, required String label}) {
    return Tooltip(
      message: label,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }
}
