import 'package:aaatp/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/views/views.dart';

class EmployeeDetails extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeDetails({super.key, required this.employee});

  @override
  State<EmployeeDetails> createState() => _EmployeeDetailsState();
}

class _EmployeeDetailsState extends State<EmployeeDetails> {
  late Future _future;
  final List<UserDataModel> _workflowUsers = [];
  int _taskCount = 0;
  int _projectCount = 0;
  int _leadsCount = 0;
  int _dealsCount = 0;

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future<void> _init() async {
    var result = await EmployeeService.getUserWorkflow(
      userId: widget.employee.uid,
    );
    var subResultMap = {};
    for (var i = 0; i < result.length; i++) {
      subResultMap[i.toString()] = result[i];
    }

    for (var i in subResultMap.entries) {
      var employee = await EmployeeService.getEmployee(uid: i.value);
      if (employee != null) {
        _workflowUsers.add(
          UserDataModel(
            uid: employee.uid ?? '',
            name: employee.name,
            desc:
                CacheService.designationByUid(employee.designation)?.name ?? '',
            userType: UserType.employee,
            profilePic: employee.profileImageUrl,
          ),
        );
      } else {
        var admin = await AdminService.getAdmin(uid: i.value);
        if (admin != null) {
          _workflowUsers.add(
            UserDataModel(
              uid: admin.uid ?? '',
              name: admin.name,
              desc: admin.email,
              userType: UserType.admin,
              profilePic: admin.profileImageUrl,
            ),
          );
        }
      }
    }

    _taskCount = await TaskService.getUserTaskCount(
      userId: widget.employee.uid ?? '',
    );
    _projectCount = await ProjectService.getUserProjectsCount(
      userId: widget.employee.uid ?? '',
    );
    _leadsCount = await LeadService.getUserLeadsCount(
      userId: widget.employee.uid ?? '',
    );
    _dealsCount = await DealService.getUserDealsCount(
      userId: widget.employee.uid ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          "Employee Portfolio",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 600;

                return SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      padding: EdgeInsets.all(isDesktop ? 24 : 16),
                      child: isDesktop
                          ? _buildDesktopLayout(context)
                          : _buildMobileLayout(context),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  /// DESKTOP LAYOUT: Dashboard Grid Arrangement
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // Top Section: Identity & Statistics
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildIdentityCard(context)),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildQuickStats(context),
                  const SizedBox(height: 16),
                  _buildReportingStructure(context),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bottom Section: Information Grid & Summary
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildInformationGrid(context, 2)),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: _buildOtherDetails(context)),
          ],
        ),
      ],
    );
  }

  /// MOBILE LAYOUT: Vertical List View
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildIdentityCard(context),
        const SizedBox(height: 12),
        _buildQuickStats(context),
        const SizedBox(height: 16),
        _buildInformationGrid(context, 1),
        const SizedBox(height: 16),
        _buildReportingStructure(context),
        const SizedBox(height: 16),
        _buildOtherDetails(context),
      ],
    );
  }

  /// PRIMARY IDENTITY CARD
  Widget _buildIdentityCard(BuildContext context) {
    final designation =
        CacheService.designationByUid(widget.employee.designation)?.name ??
        'N/A';
    final department = widget.employee.department != null
        ? widget.employee.department!
              .map((d) => CacheService.departmentByUid(d)?.name ?? '')
              .join(', ')
        : 'General';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: _glassDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFFF1F5F9),
              backgroundImage:
                  (widget.employee.profileImageUrl != null &&
                      widget.employee.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(widget.employee.profileImageUrl!)
                  : null,
              child:
                  (widget.employee.profileImageUrl == null ||
                      widget.employee.profileImageUrl!.isEmpty)
                  ? Text(
                      widget.employee.name.isNotEmpty
                          ? widget.employee.name[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.employee.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              designation,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            department,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          _buildCompactTile(
            Iconsax.personalcard,
            "Employee ID",
            widget.employee.employeeId,
          ),
          _buildCompactTile(Iconsax.sms, "Work Email", widget.employee.email),
          _buildCompactTile(
            Iconsax.call,
            "Phone",
            widget.employee.mobileNumber,
          ),
        ],
      ),
    );
  }

  /// QUICK STATS SECTION
  Widget _buildQuickStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _glassDecoration(),
      child: Row(
        children: [
          _statItem("Tasks", _taskCount, Colors.orange),
          _vDivider(),
          _statItem("Projects", _projectCount, Colors.blue),
          _vDivider(),
          _statItem("Leads", _leadsCount, Colors.red),
          _vDivider(),
          _statItem("Leads", _dealsCount, Colors.brown),
        ],
      ),
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// INFORMATION GRID: Literal GridView for desktop alignment
  Widget _buildInformationGrid(BuildContext context, int columns) {
    final infoItems = [
      {
        "label": "Official Name",
        "value": widget.employee.name,
        "icon": Iconsax.user,
      },
      {
        "label": "Employee Type",
        "value": widget.employee.employeeType ?? "Permanent",
        "icon": Iconsax.briefcase,
      },
      {
        "label": "Joining Date",
        "value": widget.employee.dateOfJoining.toLocal().toString().split(
          ' ',
        )[0],
        "icon": Iconsax.calendar_1,
      },
      {
        "label": "Date of Birth",
        "value":
            widget.employee.dateOfBirth?.toLocal().toString().split(' ')[0] ??
            "-",
        "icon": Iconsax.cake,
      },
      {"label": "Gender", "value": widget.employee.gender, "icon": Iconsax.man},
      {
        "label": "Marital Status",
        "value": widget.employee.maritalStatus,
        "icon": Iconsax.heart,
      },
    ];

    return _buildSectionCard(
      title: "Personal Information",
      icon: Iconsax.personalcard,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 20,
          childAspectRatio: columns == 1 ? 5 : 3.5,
        ),
        itemCount: infoItems.length,
        itemBuilder: (context, index) {
          final item = infoItems[index];
          return _buildDataPoint(
            item["label"].toString(),
            item["value"].toString(),
            item["icon"] as IconData,
          );
        },
      ),
    );
  }

  /// REPORTING STRUCTURE
  Widget _buildReportingStructure(BuildContext context) {
    return _buildSectionCard(
      title: "Reporting Structure",
      icon: Iconsax.hierarchy,
      child: Column(
        children: [
          if (_workflowUsers.isEmpty)
            const Text(
              "No supervisors assigned",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _workflowUsers.length,
              itemBuilder: (context, index) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: LeadsViewAppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: LeadsViewAppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            if (!(index == _workflowUsers.length - 1))
                              Expanded(
                                child: Container(
                                  width: 1,
                                  color: LeadsViewAppColors.border,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: CreatedByWidget(
                            userData: _workflowUsers[index],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherDetails(BuildContext context) {
    return _buildSectionCard(
      title: "Professional Summary",
      icon: Iconsax.info_circle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.employee.about.isEmpty
                ? "No bio provided"
                : widget.employee.about,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Skills & Expertise",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (widget.employee.skills.split(','))
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      s.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE WIDGETS ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildDataPoint(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value.isEmpty ? "-" : value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 24, color: const Color(0xFFE2E8F0));
}
