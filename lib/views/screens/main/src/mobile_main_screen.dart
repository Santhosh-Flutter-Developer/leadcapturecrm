part of 'main_screen.dart';

class MobileMainScreen extends StatefulWidget {
  final bool isAdmin;

  const MobileMainScreen({super.key, required this.isAdmin});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  late Future _future;
  late String _currentUserUid;
  EmployeeModel? _employeeModel;
  AdminModel? _adminModel;
  int _currentIndex = 0;

  final items = [
    {"icon": Iconsax.message, "label": "Messenger"},
    {"icon": Iconsax.graph, "label": "Leads"},
    {"icon": Iconsax.grid_lock, "label": "Deals"},
    {"icon": Iconsax.menu, "label": "Menu"},
  ];

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future<void> _init() async {
    try {
      if (mounted) {
        _currentUserUid = await Spdb.getUid() ?? '';
        var user = await Spdb.getUser();

        if (user.userType == UserType.admin) {
          _adminModel = await Spdb.getAdmin();
        } else {
          _employeeModel = await Spdb.getEmployee();
        }
        setState(() {});
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
    }
  }

  final String _selectedMenu = 'Dashboard';

  Widget _buildMainContentMobile() {
    switch (_currentIndex) {
      case 0:
        return ChatListing(currentUserUid: _currentUserUid);
      case 1:
        return const LeadsListing(showAppBar: false);
      case 2:
        return const DealsListing(showAppBar: false);
      case 3:
        return const MobileMenu();
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
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Splash();
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            leadingWidth: 40,
            leading: InkWell(
              onTap: () => Navigate.route(context, const Profile()),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Center(
                  child: CircleAvatar(
                    radius: 25,
                    child: Text(
                      _employeeModel != null
                          ? _employeeModel!.name.substring(0, 1).toUpperCase()
                          : _adminModel != null
                          ? _adminModel!.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(items[_currentIndex]['label'] as String),
            actions: [
              IconButton(
                icon: Icon(Iconsax.notification),
                onPressed: () =>
                    Navigate.route(context, NotificationsListing()),
                tooltip: 'Notifications',
              ),
            ],
          ),
          // drawer: const MobileSidebar(),
          body: _buildMainContentMobile(),
          bottomNavigationBar: BottomAppBar(
            elevation: 0,
            color: AppColors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: List.generate(
                    items.length,
                    (index) => _navItem(index),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(int index) {
    final bool selected = index == _currentIndex;
    final icon = items[index]["icon"] as IconData;
    final label = items[index]["label"] as String;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // full tappable area
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppColors.primary : AppColors.grey400,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.primary : AppColors.grey400,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(height: 6),
            AnimatedOpacity(
              duration: Duration(milliseconds: 220),
              opacity: selected ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                height: 6,
                width: 6,
                // ignore: deprecated_member_use
                transform: Matrix4.identity()..scale(selected ? 1.0 : 0.4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
