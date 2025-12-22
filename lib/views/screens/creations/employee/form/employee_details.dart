import 'package:flutter/material.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/views/views.dart';

class EmployeeDetails extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeDetails({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: FormWidgets.buildHeader(
        context: context,
        title: "Employee Details",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context),
                const SizedBox(height: 24),
                _buildProfileInfoCard(context),
                const SizedBox(height: 24),
                _buildAppreciationCard(context),
                const SizedBox(height: 24),
                _buildReportingCard(context),
                const SizedBox(height: 24),
                _buildAttendanceLeaveCard(context),
                const SizedBox(height: 24),
                _buildTasksCard(context),
                const SizedBox(height: 24),
                _buildTicketsCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Avatar + Basic Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.grey200,
                backgroundImage:
                    employee.profileImageUrl != null &&
                        employee.profileImageUrl!.isNotEmpty
                    ? NetworkImage(employee.profileImageUrl!)
                    : null,
                child: employee.profileImageUrl == null
                    ? const Icon(Icons.person, size: 50, color: AppColors.grey)
                    : null,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${CacheService.designationByUid(employee.designation)?.name ?? ''} • '
                      '${employee.department != null ? employee.department!.map((d) => CacheService.departmentByUid(d)?.name ?? '').join(', ') : ''}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.blueGrey,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 20,
                      runSpacing: 6,
                      children: [
                        _iconText(
                          context,
                          Icons.badge,
                          "ID: ${employee.employeeId}",
                        ),
                        _iconText(
                          context,
                          Icons.calendar_today,
                          "Joined: ${employee.dateOfJoining.toLocal().toString().split(' ')[0]}",
                        ),
                        _iconText(context, Icons.phone, employee.mobileNumber),
                        _iconText(context, Icons.email, employee.email),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom: Stat Boxes
          Row(
            children: [
              _statCard(
                context,
                Icons.folder_open_outlined,
                "Open Cards",
                "8",
                const Color(0xFFFB8C00),
              ),
              _statCard(
                context,
                Icons.work_outline,
                "Projects",
                "12",
                const Color(0xFF1E88E5),
              ),
              _statCard(
                context,
                Icons.timer_outlined,
                "Hours Logged",
                "124",
                const Color(0xFF43A047),
              ),
              _statCard(
                context,
                Icons.confirmation_num_outlined,
                "Tickets",
                "5",
                const Color(0xFFE53935),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.black54),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, "Profile Information", Icons.info_outline),
          const Divider(height: 28, thickness: 1),
          _gridInfoSection(),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.black87,
          ),
        ),
      ],
    );
  }

  Widget _gridInfoSection() {
    final infoItems = [
      {"label": "Employee ID", "value": employee.employeeId},
      {"label": "Lowercase ID", "value": employee.lowercaseEmployeeId},
      {"label": "Name", "value": employee.name},
      {"label": "Email", "value": employee.email},
      {"label": "Password", "value": employee.password},
      {
        "label": "Designation",
        "value":
            CacheService.designationByUid(employee.designation)?.name ?? '',
      },
      {
        "label": "Department",
        "value": employee.department != null
            ? employee.department!
                  .map((d) => CacheService.departmentByUid(d)?.name ?? '')
                  .where((name) => name.isNotEmpty)
                  .join(', ')
            : '',
      },
      {
        "label": "Sub Department",
        "value": employee.subDepartment != null
            ? CacheService.subDepartmentByUid(employee.subDepartment!)?.name ??
                  ''
            : '',
      },
      {"label": "Mobile Number", "value": employee.mobileNumber},
      {"label": "Gender", "value": employee.gender},
      {
        "label": "Date of Joining",
        "value": employee.dateOfJoining.toLocal().toString().split(' ')[0],
      },
      {
        "label": "Date of Birth",
        "value": employee.dateOfBirth != null
            ? employee.dateOfBirth!.toLocal().toString().split(' ')[0]
            : "-",
      },
      {
        "label": "Role",
        "value": CacheService.roleByUid(employee.role)?.name ?? '',
      },
      {"label": "Address", "value": employee.address},
      {"label": "About", "value": employee.about},
      {"label": "Login Allowed", "value": employee.loginAllowed ? "Yes" : "No"},
      {
        "label": "Receive Email Notifications",
        "value": employee.receiveEmailNotifications ? "Yes" : "No",
      },
      {"label": "Skills", "value": employee.skills},
      {"label": "Employee Type", "value": employee.employeeType ?? "-"},
      {"label": "Marital Status", "value": employee.maritalStatus},
      {
        "label": "Active Status",
        "value": employee.isActive ? "Active" : "Inactive",
      },
      {
        "label": "Created At",
        "value": employee.createdAt.toLocal().toString().split(' ')[0],
      },
      {
        "label": "Updated At",
        "value": employee.updatedAt.toLocal().toString().split(' ')[0],
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 500
            ? 2
            : 1;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 20,
            runSpacing: 12,
            children: infoItems.map((item) {
              return SizedBox(
                width: constraints.maxWidth / crossAxisCount - 24,
                child: _infoTile(context, item["label"]!, item["value"] ?? "-"),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAppreciationCard(BuildContext context) {
    return _sectionContainer(
      context: context,
      title: "Appreciations",
      icon: Icons.emoji_events_outlined,
      child: Column(
        children: [
          _appreciationTile(context, "Best Team Player", "March 2025"),
        ],
      ),
    );
  }

  Widget _appreciationTile(BuildContext context, String title, String date) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.amber.withValues(alpha: 0.15),
        child: const Icon(Icons.emoji_events, color: Colors.amber),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        date,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
      ),
    );
  }

  Widget _buildReportingCard(BuildContext context) {
    final reportingToNames = employee.reportingTo != null
        ? employee.reportingTo!
              .map((uid) => CacheService.getUserByUid(uid)?.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList()
        : [];

    final reportingToDisplay = reportingToNames.isNotEmpty
        ? reportingToNames.join(', ')
        : null;

    return _sectionContainer(
      context: context,
      title: "Reporting Structure",
      icon: Icons.people_outline,
      child: reportingToDisplay != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow("Reporting To", reportingToDisplay),
                // _InfoRow("Reporting Team", reportingTeamDisplay),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAttendanceLeaveCard(BuildContext context) {
    return _sectionContainer(
      context: context,
      title: "Attendance & Leave",
      icon: Icons.schedule_outlined,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statMiniCard(
            context,
            Icons.alarm,
            "Late Attendance",
            "3",
            AppColors.orange,
          ),
          _statMiniCard(
            context,
            Icons.beach_access_outlined,
            "Leave Taken",
            "5",
            Colors.lightBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(BuildContext context) {
    return _sectionContainer(
      context: context,
      title: "Tasks",
      icon: Icons.task_alt_outlined,
      child: Column(
        children: [
          _taskTile(
            context,
            "UI Bug Fix in Dashboard",
            "Completed",
            AppColors.success,
          ),
          _taskTile(
            context,
            "Implement New Lead Form",
            "In Progress",
            AppColors.orange,
          ),
          _taskTile(
            context,
            "CRM API Integration",
            "Pending",
            AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsCard(BuildContext context) {
    return _sectionContainer(
      context: context,
      title: "Tickets",
      icon: Icons.confirmation_num_outlined,
      child: Column(
        children: [
          _ticketTile(context, "Network Issue", "Resolved", AppColors.success),
          _ticketTile(context, "Login Error", "In Progress", AppColors.orange),
          _ticketTile(
            context,
            "Email Notification Delay",
            "Pending",
            AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _sectionContainer({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, title, icon),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.grey.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _infoTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? "-" : value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMiniCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.black54),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(
    BuildContext context,
    String title,
    String status,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, color: color, size: 14),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
      ),
      trailing: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ticketTile(
    BuildContext context,
    String title,
    String status,
    Color color,
  ) => _taskTile(context, title, status, color);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
