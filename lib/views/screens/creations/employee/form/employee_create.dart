import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/theme/theme.dart';
import '/views/views.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';

class EmployeeCreate extends StatefulWidget {
  const EmployeeCreate({super.key});

  @override
  State<EmployeeCreate> createState() => _EmployeeCreateState();
}

class _EmployeeCreateState extends State<EmployeeCreate> {
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _dateOfJoiningController =
      TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  DateTime? _selectedDateOfJoining;
  DateTime? _selectedDateOfBirth;

  bool _passwordVisible = false;
  File? _selectedProfileImage;

  List<RoleModel> _rolesList = [];
  List<DesignationModel> _designationList = [];
  List<DepartmentModel> _departmentList = [];
  final List<String> _department = [];
  final List<SubDepartmentModel> _subDepartmentList = [];
  List<EmployeeModel> _employeesList = [];
  final List<String> _reportingTo = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Future _future;

  String? _gender;
  String _loginAllowed = 'Yes';
  String _receiveEmailNotifications = 'Yes';
  String _maritalStatus = 'Single';
  String? _employeeType;

  RoleModel? _roleModel;
  DesignationModel? _designationModel;
  // DepartmentModel? _departmentModel;
  SubDepartmentModel? _subDepartmentModel;

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
      _employeesList = await EmployeeService.getAllEmployees();

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
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormWidgets.buildHeader(
                        context: context,
                        title: "Create Employee",
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
          isEdit: false,
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
    if (_selectedProfileImage != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
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
        var result = await FilePick.pickFile(
          context,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
        );
        if (result != null) {
          setState(() => _selectedProfileImage = result);
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

    const double minColumnWidth = 220.0;

    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

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
            isRequired: true,
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              splashRadius: 1,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              icon: Icon(
                _passwordVisible ? Iconsax.eye : Iconsax.eye_slash,
                size: 20,
              ),
            ),
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
                    "Designation",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              CustomFutureSearchableDropdown<DesignationModel>(
                asyncItems: () async {
                  var designations =
                      await DesignationService.getAllDesignations();
                  return designations;
                },
                itemAsString: (desigantion) => desigantion.name,
                onChanged: (selectedDes) async {
                  if (selectedDes != null) {
                    _designationModel = selectedDes;
                  }
                  setState(() {});
                },
              ),
            ],
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
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              CustomFutureSearchableDropdown<DepartmentModel>(
                asyncItems: () async {
                  var departments = await DepartmentService.getAllDepartments();
                  return departments;
                },
                multiSelect: true,
                itemAsString: (department) => department.name,
                onChangedList: (selectedDeps) async {
                  _department.clear();

                  for (var d in selectedDeps) {
                    _department.add(d.uid ?? '');
                  }

                  setState(() {});
                },
              ),
            ],
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sub Department",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              CustomFutureSearchableDropdown<SubDepartmentModel>(
                asyncItems: () async {
                  List<SubDepartmentModel> subDepartmentList = [];
                  for (var depId in _department) {
                    final list =
                        await SubDepartmentService.getSubDepartmentsByDepId(
                          depId: depId,
                        );
                    subDepartmentList.addAll(list);
                  }

                  return subDepartmentList;
                },
                itemAsString: (subDepartment) => subDepartment.name,
                onChanged: (subDepartment) async {
                  if (subDepartment != null) {
                    _subDepartmentModel = subDepartment;
                  }

                  setState(() {});
                },
              ),
            ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Role",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              CustomFutureSearchableDropdown<RoleModel>(
                asyncItems: () async {
                  var roles = await RoleService.getAllRoles();
                  return roles;
                },
                itemAsString: (role) => role.name,
                onChanged: (selectedRole) async {
                  if (selectedRole != null) {
                    _roleModel = selectedRole;
                  }
                  setState(() {});
                },
              ),
            ],
          ),

          // FormDropdownSearch(
          //   items: _rolesList.map((e) => e.name.toString()).toList(),
          //   label: 'Role',
          //   isRequired: true,
          //   onChanged: (value) {
          //     _roleModel = _rolesList.firstWhere(
          //       (element) => element.name == value,
          //     );
          //   },
          //   validator: (value) {
          //     if (value == null) {
          //       return "* Required";
          //     }
          //     return null;
          //   },
          // ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reporting To",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                CustomSearchableDropdown<String>(
                  items: _employeesList.map((e) => e.name).toList(),
                  multiSelect: true,
                  onChangedList: (selectedNames) {
                    // if (selectedNames.length > 2) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text('You can select only 2 employees.'),
                    //       duration: Duration(seconds: 2),
                    //     ),
                    //   );
                    //   return;
                    // }
                    _reportingTo.clear();

                    for (var name in selectedNames) {
                      final emp = _employeesList.firstWhere(
                        (e) => e.name == name,
                      );
                      if (!_reportingTo.contains(emp.uid) && emp.uid != null) {
                        _reportingTo.add(emp.uid!);
                      }
                    }
                  },
                  itemAsString: (s) => s,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactFormFields(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double horizontalSpacing = 16.0;
    const double verticalSpacing = 8.0;

    const double minColumnWidth = 220.0;

    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

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

    const double minColumnWidth = 220.0;

    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

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
            initialItem: 'Yes',
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
            initialItem: 'Yes',
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
            initialItem: 'Single',
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

        EmployeeModel employeeModel = EmployeeModel(
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

        await EmployeeService.createEmployee(employee: employeeModel);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);

        FlushBar.show(
          context,
          'Employee created successfully',
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
