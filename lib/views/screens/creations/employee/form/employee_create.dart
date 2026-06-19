import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
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
  final List<String> _reportingTo = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Future _future;
  int _currentStep = 0;

  String? _gender;
  String _loginAllowed = 'Yes';
  String _receiveEmailNotifications = 'Yes';
  String _maritalStatus = 'Single';
  String? _employeeType;
  String _outsideOffice = 'No';

  RoleModel? _roleModel;
  DesignationModel? _designationModel;
  // DepartmentModel? _departmentModel;
  SubDepartmentModel? _subDepartmentModel;
  EmployeeModel? employee;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _future = _init();

    if (employee != null) {
      _isActive = employee!.isActive;
    }
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

      final generatedId = await EmployeeService.generateEmployeeId();
      _employeeIdController.text = generatedId;

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

  Future<void> pickImage() async {
    // On Windows: use file picker only
    if (kIsWindows) {
      await _pickImageFromFile();
      return;
    }

    // Mobile: offer camera or gallery via bottom sheet
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final xFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
      );
      if (xFile == null) return;
      final rotated = await FlutterExifRotation.rotateImage(path: xFile.path);

      if (mounted) {
        setState(() {
          _selectedProfileImage = rotated;
        });
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      if (mounted) {
        FlushBar.show(context, 'Failed to pick image: $e', isSuccess: false);
      }
    }
  }

  /// Windows-only: Pick an image file
  Future<void> _pickImageFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        dialogTitle: 'Select a profile photo',
      );

      if (result == null || result.files.isEmpty) return;

      final pickedPath = result.files.single.path;
      if (pickedPath == null) return;

      final imageFile = File(pickedPath);

      if (mounted) {
        setState(() {
          _selectedProfileImage = imageFile;
        });
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      if (mounted) {
        FlushBar.show(context, 'Failed to pick image: $e', isSuccess: false);
      }
    }
  }

  Widget _buildStepper() {
    final steps = ["Personal", "Work", "Extra Info"];
    final primaryColor = Theme.of(context).colorScheme.primary;
    final outlineColor = Theme.of(context).colorScheme.outlineVariant;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (i) {
        // Odd indices = connector lines
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isLineActive = stepIndex < _currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(top: 17, bottom: 24),
              color: isLineActive ? primaryColor : outlineColor,
            ),
          );
        }

        final index = i ~/ 2;
        final isCompleted = index < _currentStep;
        final isActive = index == _currentStep;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isActive
                    ? primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted || isActive ? primaryColor : outlineColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isCompleted || isActive
                    ? primaryColor
                    : onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildStepper(),
                      ),
                      const SizedBox(height: 24),
                      if (_currentStep == 0) ...[
                        _buildSectionCard(
                          title: "Profile Photo",
                          child: Center(child: _buildProfileUploader()),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionCard(
                          title: "Personal Details",
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                _buildPersonalFormFields(constraints, 4),
                          ),
                        ),
                      ] else if (_currentStep == 1) ...[
                        _buildSectionCard(
                          title: "Work Details",
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                _buildWorkFormFields(constraints, 4),
                          ),
                        ),
                      ] else if (_currentStep == 2) ...[
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
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Back"),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: _currentStep < 2
                    ? ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _currentStep++;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Next"),
                      )
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Create Employee"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileUploader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    image: _selectedProfileImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedProfileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedProfileImage == null
                      ? Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    kIsWindows
                        ? Icons.upload_file_rounded
                        : Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: pickImage,
            child: Text(
              kIsWindows
                  ? (_selectedProfileImage != null
                        ? 'Tap to change photo'
                        : 'Choose Image File')
                  : (_selectedProfileImage != null
                        ? 'Tap to change photo'
                        : 'Tap to add photo'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalFormFields(BoxConstraints constraints, int gridCounts) {
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
            isRequired: isAdmin ? false : true,
            valid: (input) => Validation.commonValidation(
              input: input,
              label: 'Employee Id',
              isReq: isAdmin ? false : true,
            ),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Employee Name',
            controller: _nameController,
            hintText: 'Enter Employee Name',
            isRequired: true,
            valid: (input) => Validation.validName(
              input: input,
              label: 'Employee Name',
              isReq: true,
            ),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Email',
            controller: _emailController,
            hintText: 'Enter Email',
            isRequired: isAdmin ? true : false,
            valid: (input) => Validation.validEmail(
              input: input,
              isReq: isAdmin ? true : false,
            ),
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
                Validation.passwordValidation(input: input, isReq: true),
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
          child: FormFields(
            label: 'Mobile Number',
            controller: _mobileNumberController,
            hintText: 'Enter Mobile Number',
            valid: (input) =>
                Validation.validMobileNumber(input: input, isReq: false),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            items: const ['Male', 'Female', 'Others'],
            label: 'Gender',
            isRequired: isAdmin ? false : true,
            onChanged: (value) {
              if (value != null) {
                _gender = value.toString();
              }
            },
            validator: isAdmin
                ? null
                : (value) {
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
      ],
    );
  }

  bool isAdmin = false;

  Widget _buildWorkFormFields(BoxConstraints constraints, int gridCounts) {
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
        if (!isAdmin)
          SizedBox(
            width: itemWidth,
            child: CustomFutureSearchableDropdown<DesignationModel>(
              label: 'Designation',
              isRequired: true,
              validator: (value) {
                if (_designationModel == null) {
                  return 'Designation is required';
                }
                return null;
              },
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
          ),
        if (!isAdmin)
          SizedBox(
            width: itemWidth,
            child: CustomFutureSearchableDropdown<DepartmentModel>(
              label: 'Department',
              isRequired: true,
              validator: (value) {
                if (_department.isEmpty) {
                  return 'Department is required';
                }
                return null;
              },
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
          ),
        if (!isAdmin)
          SizedBox(
            width: itemWidth,
            child: CustomFutureSearchableDropdown<SubDepartmentModel>(
              label: 'Sub Department',
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
          ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Joining Date',
            controller: _dateOfJoiningController,
            hintText: 'DD/MM/YYYY',
            readOnly: true,
            isRequired: isAdmin ? false : true,
            valid: (input) => Validation.commonValidation(
              input: input,
              label: 'Joining Date',
              isReq: isAdmin ? false : true,
            ),
            onTap: () async {
              var result = await datePicker(context);
              if (result != null) {
                _dateOfJoiningController.text = result.formatDate;
                _selectedDateOfJoining = result;
              }
            },
          ),
        ),
        if (!isAdmin)
          SizedBox(
            width: itemWidth,
            child: CustomFutureSearchableDropdown<RoleModel>(
              label: 'Role',
              isRequired: true,
              validator: (value) {
                if (_roleModel == null) {
                  return 'Role is required';
                }
                return null;
              },
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
          ),
        if (!isAdmin)
          SizedBox(
            width: itemWidth,
            child: UsersListDropdown(
              label: 'Reporting To',
              onChangedList: (list) {
                _reportingTo.clear();
                _reportingTo.addAll(list.map((e) => e.uid!));
              },
              includeCurrentUser: false,
            ),
          ),
        Container(
          width: itemWidth,
          padding: EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: isAdmin,
                onChanged: (value) {
                  setState(() {
                    isAdmin = value ?? false;
                  });
                },
              ),
              Text("Make as Admin"),
            ],
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: Container(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Switch(
                  value: _isActive,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
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
            valid: (input) =>
                Validation.validAddress(input: input ?? '', isReq: false),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'About',
            controller: _aboutController,
            hintText: 'Enter About',
            maxLines: 2,
            valid: (input) => Validation.commonValidation(
              input: input,
              label: 'About',
              isReq: false,
            ),
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
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            items: const ['Yes', 'No'],
            initialItem: 'No',
            label: 'Allow Outside Office Punch',
            onChanged: (value) {
              if (value != null) {
                _outsideOffice = value.toString();
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
        if (isAdmin) {
          futureLoading(context);

          String? profileImageUrl;
          if (_selectedProfileImage != null) {
            profileImageUrl = await StorageService.uploadFile(
              file: _selectedProfileImage!,
              folder: StorageFolder.userPhotos,
            );
          }

          AdminModel admin = AdminModel(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            mobileNumber: _mobileNumberController.text.trim(),
            profileImageUrl: profileImageUrl,
            createdBy: await Spdb.getUser(),
          );

          await AdminService.createAdmin(admin: admin);
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.pop(context, true);

          FlushBar.show(
            context,
            'Employee created successfully',
            isSuccess: true,
          );
        } else {
          futureLoading(context);

          var duplicateError = await EmployeeService.checkEmployeeExists(
            employeeId: _employeeIdController.text,
            email: _emailController.text.trim(),
            mobileNumber: _mobileNumberController.text.trim(),
          );

          if (duplicateError != null) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            FlushBar.show(context, duplicateError, isSuccess: false);
            return;
          }

          String? profileImageUrl;
          if (_selectedProfileImage != null) {
            profileImageUrl = await StorageService.uploadFile(
              file: _selectedProfileImage!,
              folder: StorageFolder.userPhotos,
            );
          }

          EmployeeModel employee = EmployeeModel(
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
            isActive: _isActive,
            employeeType: _employeeType ?? '',
            profileImageUrl: profileImageUrl,
            skills: '',
            reportingTo: _reportingTo,
            outsideOffice: _outsideOffice == 'Yes',
            createdBy: await Spdb.getUser(),
          );

          await EmployeeService.createEmployee(employee: employee);
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.pop(context, true);

          FlushBar.show(
            context,
            'Employee created successfully',
            isSuccess: true,
          );
        }
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
