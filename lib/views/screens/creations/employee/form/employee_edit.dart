import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '/theme/theme.dart';
import '/views/views.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';

class EmployeeEdit extends StatefulWidget {
  final String uid;
  const EmployeeEdit({super.key, required this.uid});

  @override
  State<EmployeeEdit> createState() => _EmployeeEditState();
}

class _EmployeeEditState extends State<EmployeeEdit> {
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _dateOfJoiningController =
      TextEditingController();
  DateTime? _selectedDateOfJoining;
  final TextEditingController _dateOfBirthController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  bool _passwordVisible = false;

  List<RoleModel> _rolesList = [];
  List<DesignationModel> _designationList = [];
  List<DepartmentModel> _departmentList = [];
  List<SubDepartmentModel> _subDepartmentList = [];
  final List<dynamic> _initialReportingTo = [];

  final List<String> _reportingTo = [];
  final List<String> _department = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Future _future;

  String? _gender;
  String _loginAllowed = 'Yes';
  String _receiveEmailNotifications = 'Yes';
  String _maritalStatus = 'Single';
  String? _employeeType;

  File? _selectedProfileImage;
  String? _profileImageUrl;
  bool _oldProfileImageRemoved = false;

  RoleModel? _roleModel;
  DesignationModel? _designationModel;
  DepartmentModel? _departmentModel;
  SubDepartmentModel? _subDepartmentModel;
  EmployeeModel? _employeeModel;

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future<void> _init() async {
    try {
      _rolesList.clear();
      _designationList.clear();
      _departmentList.clear();
      _subDepartmentList.clear();

      _rolesList = await RoleService.getAllRoles();
      _designationList = await DesignationService.getAllDesignations();
      _departmentList = await DepartmentService.getAllDepartments();

      _employeeModel = await EmployeeService.getEmployee(uid: widget.uid);
      _employeeIdController.text = _employeeModel!.employeeId;
      _nameController.text = _employeeModel!.name;
      _emailController.text = _employeeModel!.email;
      _passwordController.text = _employeeModel!.password;
      _mobileNumberController.text = _employeeModel!.mobileNumber;
      _dateOfJoiningController.text = _employeeModel!.dateOfJoining.formatDate;
      _selectedDateOfJoining = _employeeModel!.dateOfJoining;
      _dateOfBirthController.text =
          _employeeModel!.dateOfBirth?.formatDate ?? '';
      _selectedDateOfBirth = _employeeModel!.dateOfBirth;
      _addressController.text = _employeeModel!.address;
      _aboutController.text = _employeeModel!.about;
      _skillsController.text = _employeeModel!.skills;

      _gender = _employeeModel!.gender;
      _loginAllowed = _employeeModel!.loginAllowed ? 'Yes' : 'No';
      _receiveEmailNotifications = _employeeModel!.receiveEmailNotifications
          ? 'Yes'
          : 'No';
      _maritalStatus = _employeeModel!.maritalStatus;
      _employeeType = _employeeModel!.employeeType;
      _profileImageUrl = _employeeModel!.profileImageUrl;

      _roleModel = await RoleService.getRole(uid: _employeeModel!.role);
      _designationModel = await DesignationService.getDesignation(
        uid: _employeeModel!.designation,
      );
      if (_employeeModel!.department != null &&
          _employeeModel!.department!.isNotEmpty) {
        _department.clear();
        _department.addAll(_employeeModel!.department!);
      }

      if (_departmentModel != null) {
        _subDepartmentList =
            await SubDepartmentService.getSubDepartmentsByDepId(
              depId: _departmentModel!.uid ?? '',
            );
      }

      if (_employeeModel!.subDepartment != null &&
          _employeeModel!.subDepartment!.isNotEmpty) {
        _subDepartmentModel = await SubDepartmentService.getSubDepartment(
          uid: _employeeModel!.subDepartment ?? '',
        );
      }

      _initialReportingTo.clear();
      for (var i in (_employeeModel?.reportingTo ?? [])) {
        var employee = await EmployeeService.getEmployee(uid: i);
        if (employee != null) {
          _initialReportingTo.add(employee);
        } else {
          var admin = await AdminService.getAdmin(uid: i);
          if (admin != null) {
            _initialReportingTo.add(admin);
          }
        }
      }

      setState(() {});
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      FlushBar.show(
        context,
        e.toString(),
        isSuccess: false,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileNumberController.dispose();
    _dateOfJoiningController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _skillsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: AppColors.grey50,
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

            return SingleChildScrollView(
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormWidgets.buildHeader(
                        context: context,
                        title: "Update Employee",
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: "Employee Details",
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildFormFields(constraints, 4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: "Contact Information",
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildContactFormFields(constraints, 2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: "Other Details",
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildOthersFormFields(constraints, 4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: "Profile Photo",
                        child: Center(child: _buildProfileUploader()),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: FormWidgets.buildBottomBar(
          context: context,
          onSubmit: _submitForm,
          isEdit: true,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.grey300),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileUploader() {
    if (_selectedProfileImage != null || _profileImageUrl != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _profileImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _profileImageUrl!,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.grey300,
                      highlightColor: AppColors.grey100,
                      child: Container(color: AppColors.white),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    height: 130,
                    width: 130,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    _selectedProfileImage!,
                    height: 130,
                    width: 130,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                _selectedProfileImage = null;
                if (_profileImageUrl != null) {
                  _profileImageUrl = null;
                  _oldProfileImageRemoved = true;
                }
                setState(() {});
              },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () async {
        File? result;
        if (kIsMobile) {
          result = await PickImage.selectImage(context);
        } else {
          result = await FilePick.pickFile(
            context,
            allowedExtensions: ['jpg', 'jpeg', 'png'],
          );
        }

        if (result != null) {
          _selectedProfileImage = result;
          setState(() {});
        }
      },
      child: DottedBorder(
        options: RectDottedBorderOptions(),

        child: Container(
          height: 130,
          width: 130,
          decoration: const BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.gallery, color: AppColors.grey700),
                SizedBox(height: 8),
                Text(
                  "Upload Photo",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double horizontalSpacing = 16.0;
    const double verticalSpacing = 8.0;

    // Minimum width per column (you can tweak this)
    const double minColumnWidth = 220.0;

    // Calculate the maximum number of columns that can fit
    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

    // Calculate each item width
    final double itemWidth = canShowGrid
        ? (currentWidth - horizontalSpacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: horizontalSpacing,
      runSpacing: verticalSpacing,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Employee Id',
            controller: _employeeIdController,
            hintText: 'Enter Employee Id',
            isRequired: true,
            valid: (input) => input == null || input.isEmpty
                ? 'Employee Id is required'
                : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Employee Name',
            controller: _nameController,
            hintText: 'Enter Employee Name',
            isRequired: true,
            valid: (input) => input == null || input.isEmpty
                ? 'Employee Name is required'
                : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Email',
            controller: _emailController,
            hintText: 'Enter Email',
            // isRequired: true,
            // valid: (input) =>
            //     input == null || input.isEmpty ? 'Email is required' : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Enter Password',
            isRequired: true,
            valid: (input) =>
                input == null || input.isEmpty ? 'Password is required' : null,
            obsecureText: !_passwordVisible,
            suffixIcon: IconButton(
              onPressed: () => setState(() {
                _passwordVisible = !_passwordVisible;
              }),
              icon: _passwordVisible
                  ? const Icon(Iconsax.eye)
                  : const Icon(Iconsax.eye_slash),
            ),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            initialItem:
                _designationModel != null && _designationModel!.name.isNotEmpty
                ? _designationModel?.name
                : null,
            items: _designationList.map((e) => e.name.toString()).toList(),
            label: 'Designation',
            isRequired: true,
            onChanged: (value) {
              _designationModel = _designationList.firstWhere(
                (element) => element.name == value,
              );
            },
            validator: (value) {
              if (value == null) {
                return "* Required";
              }
              return null;
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Department",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              CustomSearchableDropdown<String>(
                items: _departmentList.map((e) => e.name.toString()).toList(),
                multiSelect: true,

                initialValues: _departmentList
                    .where((d) => _department.contains(d.uid))
                    .map((d) => d.name)
                    .toList(),

                itemAsString: (s) => s,

                onChangedList: (selectedNames) async {
                  _department.clear();

                  for (var name in selectedNames) {
                    final dep = _departmentList.firstWhere(
                      (d) => d.name == name,
                    );
                    if (dep.uid != null) {
                      _department.add(dep.uid!);
                    }
                  }

                  _subDepartmentList.clear();

                  for (var depId in _department) {
                    final subDeps =
                        await SubDepartmentService.getSubDepartmentsByDepId(
                          depId: depId,
                        );
                    _subDepartmentList.addAll(subDeps);
                  }

                  setState(() {});
                },
              ),
            ],
          ),
        ),

        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            initialItem:
                _subDepartmentModel != null &&
                    _subDepartmentModel!.name.isNotEmpty
                ? _subDepartmentModel?.name
                : null,
            items: _subDepartmentList.map((e) => e.name.toString()).toList(),
            label: 'Sub Department',
            onChanged: (value) {
              _subDepartmentModel = _subDepartmentList.firstWhere(
                (element) => element.name == value,
              );
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Mobile Number',
            controller: _mobileNumberController,
            hintText: 'Enter Mobile Number',
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            initialItem: _gender != null && _gender!.isNotEmpty
                ? _gender
                : null,
            items: const ['Male', 'Female', 'Others'],
            label: 'Gender',
            isRequired: true,
            onChanged: (value) {
              if (value != null) {
                _gender = value.toString();
              }
            },
            validator: (value) {
              if (value == null) {
                return "* Required";
              }
              return null;
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Joining Date',
            controller: _dateOfJoiningController,
            hintText: 'DD/MM/YYYY',
            readOnly: true,
            isRequired: true,
            valid: (input) =>
                input == null || input.isEmpty ? '* Required' : null,
            onTap: () async {
              var result = await datePicker(context);
              if (result != null) {
                _dateOfJoiningController.text = result.formatDate;
                _selectedDateOfJoining = result;
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Birth Date',
            controller: _dateOfBirthController,
            hintText: 'DD/MM/YYYY',
            readOnly: true,
            onTap: () async {
              var result = await datePicker(context, lastDate: DateTime.now());
              if (result != null) {
                _dateOfBirthController.text = result.formatDate;
                _selectedDateOfBirth = result;
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            initialItem: _roleModel != null && _roleModel!.name.isNotEmpty
                ? _roleModel?.name
                : null,
            items: _rolesList.map((e) => e.name.toString()).toList(),
            label: 'Role',
            isRequired: true,
            onChanged: (value) {
              _roleModel = _rolesList.firstWhere(
                (element) => element.name == value,
              );
            },
            validator: (value) {
              if (value == null) {
                return "* Required";
              }
              return null;
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: UsersListDropdown(
            label: 'Reporting To',
            initialValues: _initialReportingTo,
            onChangedList: (list) {
              _reportingTo.clear();
              _reportingTo.addAll(list.map((e) => e.uid!));
            },
            includeCurrentUser: false,
          ),
        ),
      ],
    );
  }

  Widget _buildContactFormFields(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double horizontalSpacing = 16.0;
    const double verticalSpacing = 8.0;

    // Minimum width per column (you can tweak this)
    const double minColumnWidth = 220.0;

    // Calculate the maximum number of columns that can fit
    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

    // Calculate each item width
    final double itemWidth = canShowGrid
        ? (currentWidth - horizontalSpacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: horizontalSpacing,
      runSpacing: verticalSpacing,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Address',
            controller: _addressController,
            hintText: 'Enter Address',
            maxLines: 2,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'About',
            controller: _aboutController,
            hintText: 'Enter About',
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildOthersFormFields(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double horizontalSpacing = 16.0;
    const double verticalSpacing = 8.0;

    // Minimum width per column (you can tweak this)
    const double minColumnWidth = 220.0;

    // Calculate the maximum number of columns that can fit
    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

    // Calculate each item width
    final double itemWidth = canShowGrid
        ? (currentWidth - horizontalSpacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: horizontalSpacing,
      runSpacing: verticalSpacing,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            items: const ['Yes', 'No'],
            initialItem: _loginAllowed,
            label: 'Login Allowed',
            onChanged: (value) {
              if (value != null) {
                _loginAllowed = value.toString();
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            items: const ['Yes', 'No'],
            initialItem: _receiveEmailNotifications,
            label: 'Receive Email Notifications',
            onChanged: (value) {
              if (value != null) {
                _receiveEmailNotifications = value.toString();
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            items: const ['Single', 'Married'],
            initialItem: _maritalStatus,
            label: 'Marital Status',
            onChanged: (value) {
              if (value != null) {
                _maritalStatus = value.toString();
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            items: const [
              'Full Time',
              'Part Time',
              'On Contract',
              'Internship',
              'Trainee',
            ],
            label: 'Employee Type',
            initialItem: _employeeType != null && _employeeType!.isNotEmpty
                ? _employeeType
                : null,
            onChanged: (value) {
              if (value != null) {
                _employeeType = value.toString();
              }
            },
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        var employeeIdExists = await EmployeeService.checkEmployeeIdExists(
          employeeId: _employeeIdController.text,
        );

        if (employeeIdExists) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          FlushBar.show(
            context,
            'Employee ID already exists',
            isSuccess: false,
          );
        }

        String? profileImageUrl;
        if (_selectedProfileImage != null) {
          profileImageUrl = await StorageService.uploadFile(
            file: _selectedProfileImage!,
            folder: StorageFolder.userPhotos,
          );
        }

        if (_oldProfileImageRemoved) {
          await EmployeeService.deleteEmployeeImage(uid: widget.uid);
        }

        EmployeeModel employeeModel = EmployeeModel(
          uid: widget.uid,
          employeeId: _employeeIdController.text,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          designation: _designationModel?.uid ?? '',
          department: _department,
          subDepartment: _subDepartmentModel?.uid,
          mobileNumber: _mobileNumberController.text.trim(),
          gender: _gender ?? 'Male',
          dateOfJoining: _selectedDateOfJoining!,
          dateOfBirth: _selectedDateOfBirth,
          role: _roleModel?.uid ?? '',
          address: _addressController.text.trim(),
          about: _aboutController.text.trim(),
          loginAllowed: _loginAllowed == 'Yes',
          receiveEmailNotifications: _receiveEmailNotifications == 'Yes',
          maritalStatus: _maritalStatus,
          employeeType: _employeeType ?? '',
          profileImageUrl: profileImageUrl,
          skills: '',
          reportingTo: _reportingTo,
          createdBy: await Spdb.getUser(),
        );

        await EmployeeService.editEmployee(
          uid: widget.uid,
          employee: employeeModel,
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);

        FlushBar.show(
          context,
          'Employee updated successfully',
          isSuccess: true,
        );
      } catch (e, st) {
        await ErrorService.recordError(e, st);
        debugPrint("${e.toString()}, ${st.toString()}");
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        FlushBar.show(
          context,
          e.toString(),
          isSuccess: false,
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}
