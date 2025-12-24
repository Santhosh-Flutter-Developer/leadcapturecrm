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
      case "Contact Details":
        return Iconsax.call;
      case "Settings & Security":
        return Iconsax.setting_2;
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
        centerTitle: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Back(color: AppColors.black),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.w800,
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 1200
                            ? 3
                            : (constraints.maxWidth > 800 ? 2 : 1);
                        return Column(
                          children: [
                            if (!isAdmin)
                              _buildEmployeeGrid(crossAxisCount)
                            else
                              _buildAdminView(),
                            const SizedBox(height: 40),
                            _buildFooter(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = isAdmin ? admin?.name ?? "-" : employee?.name ?? "-";
    final role = isAdmin
        ? "System Administrator"
        : (CacheService.designationByUid(employee?.designation ?? '')?.name ??
              "Employee");
    final image = isAdmin ? admin?.profileImageUrl : employee?.profileImageUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: ProfileColors.white,
        border: const Border(bottom: BorderSide(color: ProfileColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ProfileColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: ProfileColors.background,
                      backgroundImage: image != null
                          ? NetworkImage(image)
                          : null,
                      child: image == null
                          ? Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: ProfileColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (!isAdmin)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: InkWell(
                        onTap: _changeProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: ProfileColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.camera,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: ProfileColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ProfileColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ACTIVE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: ProfileColors.success,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ProfileColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ProfileColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ProfileColors.border),
                        ),
                        child: Text(
                          "ID: ${employee?.employeeId ?? 'N/A'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ProfileColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          _buildDataPoint(
            "Joined Date",
            "joined",
            employee?.dateOfJoining.formatDate,
            editable: false,
          ),
        ], crossAxisCount),
        _buildResponsiveSection("Contact & Security", [
          _buildDataPoint(
            "Corporate Email",
            "email",
            employee?.email,
            editable: false,
          ),
          _buildDataPoint("Phone Number", "mobile", employee?.mobileNumber),
          _buildDataPoint("Residential Address", "address", employee?.address),
          _buildDataPoint(
            "Account Status",
            "active",
            employee?.isActive == true ? "Enabled" : "Disabled",
            editable: false,
          ),
          _buildDataPoint(
            "Email Alerts",
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

  Widget _buildAdminView() {
    return _buildResponsiveSection("Administrator Account", [
      _buildDataPoint("Name", "name", admin?.name, editable: false),
      _buildDataPoint("Email", "email", admin?.email, editable: false),
      _buildDataPoint("Mobile", "mobile", admin?.mobileNumber, editable: false),
      _buildDataPoint(
        "System Access",
        "active",
        admin?.isActive == true ? "Superuser" : "Inactive",
        editable: false,
      ),
    ], 1);
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
            : (constraints.maxWidth / gridCount) - (12 * (gridCount - 1));
        return Container(
          width: width,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ProfileColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProfileColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getSectionIcon(title),
                    size: 20,
                    color: ProfileColors.primary,
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 24),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(
                    controller: controllers[key],
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 14,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: value == null
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
    return const Center(
      child: Column(
        children: [
          Text(
            "Last synchronized with server",
            style: TextStyle(
              fontSize: 11,
              color: ProfileColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Security Patch: Dec 2023",
            style: TextStyle(fontSize: 10, color: ProfileColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
