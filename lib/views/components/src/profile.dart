import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';
import '/theme/theme.dart';

class ProfileColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF10B981);
}

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  EmployeeModel? employee;
  AdminModel? admin;
  bool isAdmin = false;
  bool isLoading = true;
  String? editingField;
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    var user = await Spdb.getUser();

    if (user.userType == UserType.admin) {
      admin = await Spdb.getAdmin();
      isAdmin = true;
    } else {
      employee = await Spdb.getEmployee();
      isAdmin = false;
    }

    if (employee != null) {
      controllers['mobile'] = TextEditingController(
        text: employee!.mobileNumber,
      );
      controllers['address'] = TextEditingController(text: employee!.address);
      controllers['about'] = TextEditingController(text: employee!.about);
      controllers['skills'] = TextEditingController(text: employee!.skills);
      controllers['maritalStatus'] = TextEditingController(
        text: employee!.maritalStatus,
      );
      controllers['name'] = TextEditingController(text: employee!.name);
    } else if (admin != null) {
      controllers['name'] = TextEditingController(text: admin!.name);
      controllers['mobile'] = TextEditingController(text: admin!.mobileNumber);
    }

    setState(() => isLoading = false);
  }

  IconData getSectionIcon(String title) {
    switch (title) {
      case "Personal Information":
        return Iconsax.user_square;
      case "Official Information":
        return Iconsax.briefcase;
      case "Contact & Security":
        return Iconsax.shield_tick;
      default:
        return Iconsax.element_3;
    }
  }

  Future<void> _changeProfileImage() async {
    if (isAdmin || employee == null) return;

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
    );

    if (pickedImage == null) return;
    File imageFile = File(pickedImage.path);

    FlushBar.show(context, "Uploading profile picture...");

    try {
      String uid = employee!.uid!;
      String fileName = "profile_$uid.jpg";
      final storageRef = FirebaseStorage.instance.ref().child(
        "profile_images/$fileName",
      );

      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      final updatedEmployee = employee!.copyWith(
        profileImageUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );
      await EmployeeService.editEmployee(
        uid: updatedEmployee.uid!,
        employee: updatedEmployee,
      );

      String? cid = await Spdb.getCid();
      await Spdb.setEmployeeLogin(model: updatedEmployee, cid: cid ?? '');

      setState(() => employee = updatedEmployee);
      FlushBar.show(
        context,
        "Profile picture updated successfully",
        isSuccess: true,
      );
    } catch (e) {
      FlushBar.show(
        context,
        "Failed to update profile picture: $e",
        isSuccess: false,
      );
    }
  }

  Future<void> _saveSingleField(String key) async {
    if (employee == null) return;
    String? cid = await Spdb.getCid();
    String newValue = controllers[key]?.text.trim() ?? '';

    try {
      final updatedEmployee = employee!.copyWith(
        name: key == 'name' ? newValue : employee!.name,
        mobileNumber: key == 'mobile' ? newValue : employee!.mobileNumber,
        address: key == 'address' ? newValue : employee!.address,
        about: key == 'about' ? newValue : employee!.about,
        skills: key == 'skills' ? newValue : employee!.skills,
        maritalStatus: key == 'maritalStatus'
            ? newValue
            : employee!.maritalStatus,
        updatedAt: DateTime.now(),
      );

      await EmployeeService.editEmployee(
        uid: updatedEmployee.uid!,
        employee: updatedEmployee,
      );
      await Spdb.setEmployeeLogin(model: updatedEmployee, cid: cid ?? '');

      setState(() {
        employee = updatedEmployee;
        editingField = null;
      });

      FlushBar.show(context, "Information updated", isSuccess: true);
    } catch (e) {
      FlushBar.show(context, "Update failed: $e", isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: ProfileColors.white,
        elevation: 0,
        leading: const Back(color: AppColors.black),
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ProfileColors.textPrimary,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: ProfileColors.border, height: 1),
        ),
      ),
      body: isLoading
          ? const Center(child: WaitingLoading())
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 1000;
                return SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      padding: EdgeInsets.all(isDesktop ? 40 : 16),
                      child: isDesktop
                          ? _buildDesktopLayout()
                          : _buildMobileLayout(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// DESKTOP LAYOUT: Sticky Side Card + Main Content
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Profile Card
        SizedBox(
          width: 350,
          child: Column(
            children: [
              _buildStickyProfileCard(),
              const SizedBox(height: 24),
              _buildStatsCard(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right Column: Information Sections
        Expanded(
          child: Column(
            children: [
              _buildEmployeeGrid(2), // 2 columns for sections on desktop
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  /// MOBILE LAYOUT: Vertical Stack
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 24),
        _buildEmployeeGrid(1),
        const SizedBox(height: 40),
        _buildFooter(),
      ],
    );
  }

  Widget _buildStickyProfileCard() {
    final name = isAdmin ? admin?.name ?? "-" : employee?.name ?? "-";
    final role = isAdmin
        ? "System Administrator"
        : (CacheService.designationByUid(employee?.designation ?? '')?.name ??
              "Employee");
    final image = isAdmin ? admin?.profileImageUrl : employee?.profileImageUrl;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ProfileColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProfileColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ProfileColors.primary.withValues(alpha: 0.1),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: ProfileColors.background,
                  backgroundImage: image != null ? NetworkImage(image) : null,
                  child: image == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: ProfileColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              if (!isAdmin)
                Material(
                  color: ProfileColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _changeProfileImage,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(
                        Iconsax.camera,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ProfileColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: ProfileColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildInfoTile(
            Iconsax.personalcard,
            "Employee ID",
            employee?.employeeId ?? "N/A",
          ),
          _buildInfoTile(
            Iconsax.sms,
            "Corporate Email",
            employee?.email ?? admin?.email ?? "-",
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProfileColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProfileColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Status", "Active", ProfileColors.success),
          Container(width: 1, height: 40, color: ProfileColors.border),
          _buildStatItem(
            "Joined",
            employee?.dateOfJoining.formatDate.split(' ').first ?? "-",
            ProfileColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: ProfileColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ProfileColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ProfileColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ProfileColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile fallback header
  Widget _buildProfileHeader() {
    return _buildStickyProfileCard();
  }

  Widget _buildEmployeeGrid(int crossAxisCount) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _buildResponsiveSection("Personal Information", [
          _buildDataPoint("Full Name", "name", employee?.name),
          _buildDataPoint(
            "Gender",
            "gender",
            employee?.gender,
            editable: false,
          ),
          _buildDataPoint(
            "Date of Birth",
            "dob",
            employee?.dateOfBirth?.formatDate,
            editable: false,
          ),
          _buildDataPoint(
            "Marital Status",
            "maritalStatus",
            employee?.maritalStatus,
          ),
          _buildDataPoint("About Me", "about", employee?.about),
          _buildDataPoint("Special Skills", "skills", employee?.skills),
        ], crossAxisCount),
        _buildResponsiveSection("Official Information", [
          _buildDataPoint(
            "Employment",
            "employeeType",
            employee?.employeeType,
            editable: false,
          ),
          _buildDataPoint(
            "Role Type",
            "role",
            CacheService.roleByUid(employee?.role ?? '')?.name ?? '',
            editable: false,
          ),
          _buildDataPoint(
            "Department",
            "dept",
            (employee?.department ?? [])
                .map((u) => CacheService.departmentByUid(u)?.name ?? '')
                .join(', '),
            editable: false,
          ),
          _buildDataPoint(
            "Manager",
            "manager",
            (employee?.reportingTo ?? [])
                .map((u) => CacheService.getUserByUid(u)?.name ?? '')
                .join(', '),
            editable: false,
          ),
        ], crossAxisCount),
        _buildResponsiveSection("Contact & Security", [
          _buildDataPoint("Phone Number", "mobile", employee?.mobileNumber),
          _buildDataPoint("Residential Address", "address", employee?.address),
          _buildDataPoint(
            "Email Notifications",
            "notif",
            employee?.receiveEmailNotifications == true
                ? "Subscribed"
                : "Muted",
            editable: false,
          ),
        ], crossAxisCount),
      ],
    );
  }

  Widget _buildResponsiveSection(
    String title,
    List<Widget> items,
    int gridCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = gridCount == 1
            ? double.infinity
            : (constraints.maxWidth / gridCount) - 12;
        return Container(
          width: width,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: ProfileColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ProfileColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ProfileColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      getSectionIcon(title),
                      size: 20,
                      color: ProfileColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ProfileColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ...items,
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataPoint(
    String label,
    String key,
    String? value, {
    bool editable = true,
  }) {
    bool isEditing = editingField == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ProfileColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (isEditing)
                  TextField(
                    controller: controllers[key],
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  )
                else
                  Text(
                    value != null && value.isNotEmpty ? value : "Not Specified",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: (value == null || value.isEmpty)
                          ? ProfileColors.textSecondary
                          : ProfileColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          if (editable && !isAdmin)
            IconButton(
              onPressed: () {
                if (isEditing) {
                  _saveSingleField(key);
                } else {
                  setState(() => editingField = key);
                }
              },
              icon: Icon(
                isEditing ? Iconsax.tick_circle : Iconsax.edit,
                size: 18,
                color: ProfileColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Text(
              "Data synchronized with secure server",
              style: TextStyle(
                fontSize: 11,
                color: ProfileColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Security Patch: ${AppPackageInfo.version} • ${DateTime.now().monthYearFormat}",
              style: TextStyle(
                fontSize: 10,
                color: ProfileColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
