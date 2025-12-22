import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';

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
  bool isEditing = false;
  String? editingField;
  final Map<String, TextEditingController> controllers = {};
  final List<String> _reportingTo = [];
  final List<String> _department = [];

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
    } else {
      employee = await Spdb.getEmployee();
    }

    setState(() => isLoading = false);

    if (employee != null) {
      // controllers['name'] = TextEditingController(text: employee!.name);
      controllers['mobile'] = TextEditingController(
        text: employee!.mobileNumber,
      );
      controllers['address'] = TextEditingController(text: employee!.address);
      // controllers['department'] = TextEditingController(
      //   text: employee!.department,
      // );
      // controllers['designation'] = TextEditingController(
      //   text: employee!.designation,
      // );
      controllers['about'] = TextEditingController(text: employee!.about);
      controllers['skills'] = TextEditingController(text: employee!.skills);
      // controllers['role'] = TextEditingController(text: employee!.role);
      // controllers['maritalStatus'] = TextEditingController(
      //   text: employee!.maritalStatus,
      // );
      // controllers['subDepartment'] = TextEditingController(
      //   text: employee!.subDepartment,
      // );
      // controllers['employeeType'] = TextEditingController(
      //   text: employee!.employeeType,
      // );
      // controllers['reportingTo'] = TextEditingController(
      //   text: employee!.reportingTo,
      // );
    }
  }

  IconData getSectionIcon(String title) {
    switch (title) {
      case "Personal Information":
        return Iconsax.profile_circle;
      case "Official Information":
        return Iconsax.briefcase;
      case "Contact Details":
        return Iconsax.call;
      case "Settings":
        return Iconsax.setting_2;
      default:
        return Iconsax.element_3; // fallback
    }
  }

  Future<void> _changeProfileImage() async {
    if (employee == null) return;
    if (isAdmin) return; // Assuming admins can't change their pic this way

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
    );

    if (pickedImage == null) return;

    File imageFile = File(pickedImage.path);

    // Show loading indicator
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

      FlushBar.show(context, "Profile picture updated");
    } catch (e) {
      FlushBar.show(context, "Failed to update profile picture: $e");
    }
  }

  // void _updateBooleanField(String key, bool newValue) {
  //   setState(() {
  //     if (employee == null) return;

  //     switch (key) {
  //       case "loginAllowed":
  //         employee = employee!.copyWith(loginAllowed: newValue);
  //         break;

  //       case "receiveEmailNotifications":
  //         employee = employee!.copyWith(receiveEmailNotifications: newValue);
  //         break;

  //       case "isActive":
  //         employee = employee!.copyWith(isActive: newValue);
  //         break;
  //     }
  //   });

  //   _saveSingleField(key, overrideValue: newValue.toString());
  // }

  Widget _buildCardSection(String title, List<Widget> items) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero, // Margin will be handled by the parent grid
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getSectionIcon(title),
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.grey200),
              const SizedBox(height: 10),

              Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        color: AppColors.grey200,
                        thickness: 0.5,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String label, String key, String? value) {
    bool isThisEditing = editingField == key;
    bool isEditableField = controllers.containsKey(key);
    bool isBoolField = value == "true" || value == "false";

    Widget? trailingWidget;
    if (isBoolField) {
      trailingWidget = IgnorePointer(
        ignoring: true,
        child: Switch(
          value: value == "true",
          onChanged: (_) {},
          // (newVal) {
          //   _updateBooleanField(key, newVal);
          // },
          activeThumbColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else if (isEditableField) {
      trailingWidget = IconButton(
        icon: Icon(
          isThisEditing ? Icons.check_circle_outline : Iconsax.edit,
          size: 22,
          color: AppColors.primary,
        ),
        onPressed: () {
          if (isThisEditing) {
            _saveSingleField(key);
          } else {
            setState(() => editingField = key);
          }
        },
      );
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 2.0,
        horizontal: 0.0,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.grey600,
        ),
      ),
      subtitle: isThisEditing
          ? TextField(
              controller: controllers[key],
              autofocus: true,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.black),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(top: 4),
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            )
          : (isBoolField
                ? null // No subtitle if it's a switch
                : Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      value != null && value.isNotEmpty ? value : "Not set",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.black),
                    ),
                  )),
      trailing: trailingWidget,
    );
  }

  Future<void> _saveSingleField(String key, {String? overrideValue}) async {
    if (employee == null) return;

    // Show loading
    FlushBar.show(context, "Updating $key...");

    try {
      String? cid = await Spdb.getCid();

      final updatedEmployee = employee!.copyWith(
        name: key == 'name'
            ? (overrideValue ?? controllers['name']?.text)
            : employee!.name,
        mobileNumber: key == 'mobile'
            ? (overrideValue ?? controllers['mobile']?.text)
            : employee!.mobileNumber,
        address: key == 'address'
            ? (overrideValue ?? controllers['address']?.text)
            : employee!.address,
        department: key == 'department' ? _department : employee!.department,
        designation: key == 'designation'
            ? (overrideValue ?? controllers['designation']?.text)
            : employee!.designation,
        loginAllowed: key == 'loginAllowed'
            ? (overrideValue == "true")
            : employee!.loginAllowed,
        receiveEmailNotifications: key == 'receiveEmailNotifications'
            ? (overrideValue == "true")
            : employee!.receiveEmailNotifications,
        isActive: key == 'isActive'
            ? (overrideValue == "true")
            : employee!.isActive,
        updatedAt: DateTime.now(),
        about: key == 'about'
            ? (overrideValue ?? controllers['about']?.text)
            : employee!.about,
        skills: key == 'skills'
            ? (overrideValue ?? controllers['skills']?.text)
            : employee!.skills,
        role: key == 'role'
            ? (overrideValue ?? controllers['role']?.text)
            : employee!.role,
        maritalStatus: key == 'maritalStatus'
            ? (overrideValue ?? controllers['maritalStatus']?.text)
            : employee!.maritalStatus,
        subDepartment: key == 'subDepartment'
            ? (overrideValue ?? controllers['subDepartment']?.text)
            : employee!.subDepartment,
        employeeType: key == 'employeeType'
            ? (overrideValue ?? controllers['employeeType']?.text)
            : employee!.employeeType,
        reportingTo: key == 'reportingTo'
            ? _reportingTo
            : employee!.reportingTo,
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

      FlushBar.show(context, "${key.capitalizeFirst} updated successfully");
    } catch (e) {
      FlushBar.show(context, "Failed to update $key: $e");
    }
  }

  Widget _buildProfileHeader() {
    final profileName = isAdmin ? admin?.name ?? "-" : employee?.name ?? "-";
    final profileRole = isAdmin
        ? "Administrator"
        : (employee?.designation ?? "Employee");
    final profileImage = isAdmin
        ? admin?.profileImageUrl
        : employee?.profileImageUrl;
    final profileLetter = profileName.isNotEmpty
        ? profileName.substring(0, 1).toUpperCase()
        : "?";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.grey200, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _changeProfileImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.grey300,
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null
                        ? Text(
                            profileLetter,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          )
                        : null,
                  ),
                ),
                if (!isAdmin) // Only show camera icon for employees
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Iconsax.camera,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profileRole.isNotEmpty
                      ? CacheService.designationByUid(profileRole)?.name ?? ''
                      : '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: Back(), elevation: 0, title: Text("Profile")),
      body: isLoading
          ? const Center(child: WaitingLoading())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),

                  if (!isAdmin && employee != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth;
                          // Responsive grid count
                          int crossAxisCount = maxWidth > 1200
                              ? 3
                              : maxWidth > 800
                              ? 2
                              : 1;

                          // Calculate width for each item to maintain padding
                          double itemWidth =
                              (maxWidth - (16 * (crossAxisCount - 1))) /
                              crossAxisCount;

                          // Set a reasonable child aspect ratio
                          double childAspectRatio =
                              itemWidth / 550; // Adjust 550 to fit content

                          if (crossAxisCount == 1) {
                            // For single column, let width be full and height be auto
                            return Column(
                              children: [
                                _buildCardSection("Personal Information", [
                                  _buildItem(
                                    "Employee ID",
                                    "employeeId",
                                    employee?.employeeId,
                                  ),
                                  _buildItem("Name", "name", employee?.name),
                                  _buildItem(
                                    "Gender",
                                    "gender",
                                    employee?.gender,
                                  ),
                                  _buildItem(
                                    "Date of Birth",
                                    "dob",
                                    employee?.dateOfBirth != null
                                        ? employee?.dateOfBirth!.formatDate
                                        : '',
                                  ),
                                  _buildItem(
                                    "Marital Status",
                                    "maritalStatus",
                                    employee?.maritalStatus,
                                  ),
                                  _buildItem(
                                    "Role",
                                    "role",
                                    employee?.role != null &&
                                            employee!.role.isNotEmpty
                                        ? CacheService.roleByUid(
                                                employee?.role ?? '',
                                              )?.name ??
                                              ''
                                        : '',
                                  ),
                                  _buildItem("About", "about", employee?.about),
                                  _buildItem(
                                    "Skills",
                                    "skills",
                                    employee?.skills,
                                  ),
                                  _buildItem(
                                    "Created At",
                                    "createdAt",
                                    employee?.createdAt
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first,
                                  ),
                                  _buildItem(
                                    "Updated At",
                                    "updatedAt",
                                    employee?.updatedAt
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first,
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _buildCardSection("Official Information", [
                                  _buildItem(
                                    "Designation",
                                    "designation",
                                    employee?.designation != null &&
                                            employee!.designation.isNotEmpty
                                        ? CacheService.designationByUid(
                                                employee?.designation ?? '',
                                              )?.name ??
                                              ''
                                        : '',
                                  ),
                                  _buildItem(
                                    "Department",
                                    "department",
                                    employee?.reportingTo != null &&
                                            employee!.reportingTo!.isNotEmpty
                                        ? employee!.reportingTo!
                                              .map(
                                                (uid) =>
                                                    CacheService.departmentByUid(
                                                      uid,
                                                    )?.name ??
                                                    '',
                                              )
                                              .join(', ')
                                        : '',
                                  ),
                                  _buildItem(
                                    "Sub Department",
                                    "subDepartment",
                                    employee?.subDepartment != null &&
                                            employee!.subDepartment!.isNotEmpty
                                        ? CacheService.subDepartmentByUid(
                                                employee?.subDepartment ?? '',
                                              )?.name ??
                                              ''
                                        : '',
                                  ),
                                  _buildItem(
                                    "Employee Type",
                                    "employeeType",
                                    employee?.employeeType,
                                  ),
                                  _buildItem(
                                    "Reporting To",
                                    "reportingTo",
                                    employee?.reportingTo != null &&
                                            employee!.reportingTo!.isNotEmpty
                                        ? employee!.reportingTo!
                                              .map(
                                                (uid) =>
                                                    CacheService.getUserByUid(
                                                      uid,
                                                    )?.name ??
                                                    '',
                                              )
                                              .join(', ')
                                        : '',
                                  ),
                                  _buildItem(
                                    "Date of Joining",
                                    "joiningDate",
                                    employee?.dateOfJoining
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first,
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _buildCardSection("Contact Details", [
                                  _buildItem("Email", "email", employee?.email),
                                  _buildItem(
                                    "Mobile",
                                    "mobile",
                                    employee?.mobileNumber,
                                  ),
                                  _buildItem(
                                    "Address",
                                    "address",
                                    employee?.address,
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _buildCardSection("Settings", [
                                  _buildItem(
                                    "Login Allowed",
                                    "loginAllowed",
                                    employee?.loginAllowed.toString(),
                                  ),
                                  _buildItem(
                                    "Email Notifications",
                                    "receiveEmailNotifications",
                                    employee?.receiveEmailNotifications
                                        .toString(),
                                  ),
                                  _buildItem(
                                    "Active",
                                    "isActive",
                                    employee?.isActive.toString(),
                                  ),
                                ]),
                              ],
                            );
                          }

                          // Use GridView for multi-column layout
                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: childAspectRatio,
                                ),
                            children: [
                              _buildCardSection("Personal Information", [
                                _buildItem(
                                  "Employee ID",
                                  "employeeId",
                                  employee?.employeeId,
                                ),
                                _buildItem("Name", "name", employee?.name),
                                _buildItem(
                                  "Gender",
                                  "gender",
                                  employee?.gender,
                                ),
                                _buildItem(
                                  "Date of Birth",
                                  "dob",
                                  employee?.dateOfBirth
                                      ?.toLocal()
                                      .toString()
                                      .split(' ')
                                      .first,
                                ),
                                _buildItem(
                                  "Marital Status",
                                  "maritalStatus",
                                  employee?.maritalStatus,
                                ),
                                _buildItem(
                                  "Role",
                                  "role",
                                  employee?.role != null &&
                                          employee!.role.isNotEmpty
                                      ? CacheService.roleByUid(
                                              employee?.role ?? '',
                                            )?.name ??
                                            ''
                                      : '',
                                ),
                                _buildItem("About", "about", employee?.about),
                                _buildItem(
                                  "Skills",
                                  "skills",
                                  employee?.skills,
                                ),
                                _buildItem(
                                  "Created At",
                                  "createdAt",
                                  employee?.createdAt.formatDate,
                                ),
                                _buildItem(
                                  "Updated At",
                                  "updatedAt",
                                  employee?.updatedAt.formatDate,
                                ),
                              ]),
                              _buildCardSection("Official Information", [
                                _buildItem(
                                  "Designation",
                                  "designation",
                                  employee?.designation != null &&
                                          employee!.designation.isNotEmpty
                                      ? CacheService.designationByUid(
                                              employee?.designation ?? '',
                                            )?.name ??
                                            ''
                                      : '',
                                ),
                                _buildItem(
                                  "Department",
                                  "department",
                                  employee?.department != null &&
                                          employee!.department!.isNotEmpty
                                      ? employee!.department!
                                            .map(
                                              (uid) =>
                                                  CacheService.departmentByUid(
                                                    uid,
                                                  )?.name ??
                                                  '',
                                            )
                                            .where((name) => name.isNotEmpty)
                                            .join(', ')
                                      : '',
                                ),
                                _buildItem(
                                  "Sub Department",
                                  "subDepartment",
                                  employee?.subDepartment != null &&
                                          employee!.subDepartment!.isNotEmpty
                                      ? CacheService.subDepartmentByUid(
                                              employee?.subDepartment ?? '',
                                            )?.name ??
                                            ''
                                      : '',
                                ),
                                _buildItem(
                                  "Employee Type",
                                  "employeeType",
                                  employee?.employeeType,
                                ),
                                _buildItem(
                                  "Reporting To",
                                  "reportingTo",
                                  employee?.reportingTo != null &&
                                          employee!.reportingTo!.isNotEmpty
                                      ? employee!.reportingTo!
                                            .map(
                                              (uid) =>
                                                  CacheService.getUserByUid(
                                                    uid,
                                                  )?.name ??
                                                  '',
                                            )
                                            .where((name) => name.isNotEmpty)
                                            .join(', ')
                                      : '',
                                ),
                                _buildItem(
                                  "Date of Joining",
                                  "joiningDate",
                                  employee?.dateOfJoining.formatDate,
                                ),
                              ]),
                              _buildCardSection("Contact Details", [
                                _buildItem("Email", "email", employee?.email),
                                _buildItem(
                                  "Mobile",
                                  "mobile",
                                  employee?.mobileNumber,
                                ),
                                _buildItem(
                                  "Address",
                                  "address",
                                  employee?.address,
                                ),
                              ]),
                              _buildCardSection("Settings", [
                                _buildItem(
                                  "Login Allowed",
                                  "loginAllowed",
                                  employee?.loginAllowed.toString(),
                                ),
                                _buildItem(
                                  "Email Notifications",
                                  "receiveEmailNotifications",
                                  employee?.receiveEmailNotifications
                                      .toString(),
                                ),
                                _buildItem(
                                  "Active",
                                  "isActive",
                                  employee?.isActive.toString(),
                                ),
                              ]),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  if (isAdmin && admin != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 800;
                          double cardWidth = isWide
                              ? (constraints.maxWidth / 2) - 8
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _buildCardSection("Admin Information", [
                                  _buildItem("Name", "name", admin?.name),
                                  _buildItem("Email", "email", admin?.email),
                                  _buildItem(
                                    "Mobile",
                                    "mobile",
                                    admin?.mobileNumber,
                                  ),
                                  _buildItem(
                                    "Active",
                                    "isActive",
                                    admin?.isActive.toString(),
                                  ),
                                  _buildItem(
                                    "Created At",
                                    "createdAt",
                                    admin?.createdAt
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first,
                                  ),
                                ]),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
