import 'package:flutter/material.dart';
import '/services/services.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/views/views.dart';

class SubDepartmentCreate extends StatefulWidget {
  const SubDepartmentCreate({super.key});

  @override
  State<SubDepartmentCreate> createState() => _SubDepartmentCreateState();
}

class _SubDepartmentCreateState extends State<SubDepartmentCreate> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<DepartmentModel> _departmentList = [];

  String? _selectedDepartmentUid;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final departments = await DepartmentService.getAllDepartments();
    setState(() {
      _departmentList.addAll(departments);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
        body: Column(
          children: [
            FormWidgets.buildHeader(
              context: context,
              title: "Create Sub Department",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 500),
                  child: Card(
                    color: AppColors.white,
                    elevation: 7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.grey200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sub Department Information",
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Divider(color: AppColors.grey300, thickness: 1),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) =>
                                _buildFormFields(constraints),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: FormWidgets.buildBottomBar(
          context: context,
          onSubmit: _submitForm,
          isEdit: false,
        ),
      ),
    );
  }

  Widget _buildFormFields(BoxConstraints constraints) {
    final double currentWidth = constraints.maxWidth;
    const double horizontalSpacing = 16.0;
    const double verticalSpacing = 8.0;

    const double minColumnWidth = 220.0;

    final bool canShowGrid =
        currentWidth >= (minColumnWidth * 3 + horizontalSpacing * (3 - 1));

    final double itemWidth = canShowGrid
        ? (currentWidth - horizontalSpacing * (3 - 1)) / 3
        : currentWidth;

    return Form(
      key: _formKey,
      child: Wrap(
        spacing: horizontalSpacing,
        runSpacing: verticalSpacing,
        children: [
          SizedBox(
            width: itemWidth,
            child: FormFields(
              label: 'Sub Department Name',
              controller: _nameController,
              hintText: 'Enter sub department name',
              isRequired: true,
              valid: (input) => input == null || input.isEmpty
                  ? 'Sub Department Name is required'
                  : null,
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: FormDropdownSearch(
              label: 'Select Department',
              isRequired: true,
              items: _departmentList.map((e) => e.name).toList(),
              onChanged: (value) {
                if (value != null) {
                  _selectedDepartmentUid = _departmentList
                      .firstWhere((element) => element.name == value.toString())
                      .uid;
                }
              },
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: FormFields(
              label: 'Description',
              controller: _descriptionController,
              hintText: 'Enter description (optional)',
              maxLines: 2,
              keyboardType: TextInputType.multiline,
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);
        SubDepartmentModel subDepartmentModel = SubDepartmentModel(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          department: _selectedDepartmentUid ?? '',
          createdBy: await Spdb.getUser(),
        );

        await SubDepartmentService.createSubDepartment(
          subDepartment: subDepartmentModel,
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);

        FlushBar.show(
          context,
          'Sub Department created successfully',
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
