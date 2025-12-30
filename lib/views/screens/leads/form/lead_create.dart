import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '/models/models.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/views/views.dart';

class LeadCreate extends StatefulWidget {
  const LeadCreate({super.key});

  @override
  State<LeadCreate> createState() => _LeadCreateState();
}

class _LeadCreateState extends State<LeadCreate> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _leadNameController = TextEditingController();

  final TextEditingController _leadEmailController = TextEditingController();
  final TextEditingController _leadValueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyWebsiteController =
      TextEditingController();
  final TextEditingController _companyMobileController =
      TextEditingController();
  final TextEditingController _companyCountryController =
      TextEditingController();
  final TextEditingController _companyStateController = TextEditingController();
  final TextEditingController _companyCityController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyZipController = TextEditingController();

  String? _salutation;

  bool _allowFollowUp = true;

  bool _showCompanyDetails = false;
  late Future _future;

  List<LeadCategoryModel> _leadCategories = [];
  LeadCategoryModel? _selectedLeadCategory;
  List<LeadPriorityModel> _leadPriorities = [];
  LeadPriorityModel? _selectedLeadPriority;
  List<LeadStatusModel> _leadStatus = [];
  LeadStatusModel? _leadStatusModel;
  List<LeadSourceModel> _leadSource = [];
  LeadSourceModel? _selectedLeadSource;
  RegionModel? _regionModel;
  StateModel? _stateModel;
  CityModel? _cityModel;

  final List<File> _selectedAttachments = [];

  @override
  void initState() {
    _future = _init();

    super.initState();
  }

  Future<void> _init() async {
    try {
      _leadCategories.clear();
      _leadPriorities.clear();
      _leadStatus.clear();
      _leadSource.clear();
      _leadCategories = await LeadCategoryService.getAllLeadCategories();
      _leadPriorities = await LeadPriorityService.getAllLeadPriority();
      _leadStatus = await LeadStatusService.getAllLeadStatus();
      _leadSource = await LeadSourceService.getAllLeadSource();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
  }

  @override
  void dispose() {
    _leadNameController.dispose();
    _leadEmailController.dispose();
    _leadValueController.dispose();
    _notesController.dispose();
    _companyNameController.dispose();
    _companyWebsiteController.dispose();
    _companyMobileController.dispose();
    _companyCountryController.dispose();
    _companyStateController.dispose();
    _companyCityController.dispose();
    _companyAddressController.dispose();
    _companyZipController.dispose();
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
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              return Column(
                children: [
                  FormWidgets.buildHeader(
                    context: context,
                    title: "Create Leads",
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildSectionCard(
                              "Lead Details",
                              LayoutBuilder(
                                builder: (context, constraints) =>
                                    _buildLeadDetails(constraints, 3),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              "Company Details",
                              LayoutBuilder(
                                builder: (context, constraints) =>
                                    _buildCompanyDetails(constraints, 3),
                              ),
                              expandable: true,
                            ),
                            const SizedBox(height: 15),
                            _buildSectionCard(
                              "Attachments",
                              LayoutBuilder(
                                builder: (context, constraints) =>
                                    _buildAttachmentDetails(constraints, 3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
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

  Widget _buildAttachmentDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double horizontalSpacing = 16.0;

    const double minColumnWidth = 220.0;

    final bool canShowGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + horizontalSpacing * (gridCounts - 1));

    final double itemWidth = canShowGrid
        ? (currentWidth - horizontalSpacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: "Attachments",
            hintText: "Tap to select files",
            suffixIcon: const Icon(Iconsax.document_upload),
            readOnly: true,
            onTap: () async {
              var files = await FilePick.pickFiles(context);
              if (files != null) {
                if (files.isNotEmpty) {
                  _selectedAttachments.addAll(files);
                  setState(() {});
                }
              }
            },
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: _selectedAttachments.map((file) {
            return Chip(
              label: Text(
                path.basename(file.path),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onDeleted: () {
                _selectedAttachments.remove(file);
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    Widget child, {
    bool expandable = false,
  }) {
    return Card(
      color: AppColors.white,
      elevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: expandable
                  ? () => setState(
                      () => _showCompanyDetails = !_showCompanyDetails,
                    )
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if (expandable)
                    Icon(
                      _showCompanyDetails
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                ],
              ),
            ),
            if (!expandable || _showCompanyDetails) ...[
              const SizedBox(height: 16),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDetails(BoxConstraints constraints, int gridCounts) {
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
            label: 'Salutation',
            items: const ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
            onChanged: (value) => _salutation = value as String?,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Lead Name',
            controller: _leadNameController,
            hintText: 'e.g. John Doe',
            isRequired: true,
            valid: (input) =>
                input == null || input.isEmpty ? 'Required' : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Lead Email',
            controller: _leadEmailController,
            hintText: 'e.g. email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Lead Source',
            items: _leadSource.map((e) => e.name).toList(),
            onChanged: (value) {
              _selectedLeadSource = _leadSource.firstWhere(
                (cat) => cat.name == value,
                orElse: () => _leadSource.first,
              );
            },
            validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Lead Category',
            items: _leadCategories.map((e) => e.name).toList(),
            onChanged: (value) {
              _selectedLeadCategory = _leadCategories.firstWhere(
                (cat) => cat.name == value,
                orElse: () => _leadCategories.first,
              );
            },
            validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Lead Priority',
            items: _leadPriorities.map((e) => e.name).toList(),
            onChanged: (value) {
              _selectedLeadPriority = _leadPriorities.firstWhere(
                (cat) => cat.name == value,
                orElse: () => _leadPriorities.first,
              );
            },
            validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label:
                'Lead Value ${_regionModel != null ? '(${_regionModel?.currencySymbol})' : ''}',
            controller: _leadValueController,
            hintText: 'Enter Amount',
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Allow Follow Up',
            items: const ['Yes', 'No'],
            initialItem: 'Yes',
            onChanged: (value) =>
                _allowFollowUp = value == 'Yes' ? true : false,
            validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Status',
            items: _leadStatus.map((e) => e.name).toList(),
            onChanged: (value) {
              _leadStatusModel = _leadStatus.firstWhere(
                (element) => element.name == value,
              );
            },
            validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Note',
            controller: _notesController,
            hintText: 'Enter Note...',
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDetails(constraints, gridCounts) {
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
            label: 'Company Name',
            controller: _companyNameController,
            hintText: 'Enter Company Name',
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Website',
            controller: _companyWebsiteController,
            hintText: 'Enter Website URL',
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Mobile',
            controller: _companyMobileController,
            hintText: 'Enter Mobile Number',
            keyboardType: TextInputType.phone,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: CustomFutureSearchableDropdown<RegionModel>(
            label: 'Country',
            asyncItems: () async {
              var countries = await RegionService.getCountries();
              return countries;
            },
            itemAsString: (countries) => countries.name,
            onChanged: (selectedCountry) async {
              _regionModel = selectedCountry;
              setState(() {});
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: CustomFutureSearchableDropdown<StateModel>(
            label: 'State',
            asyncItems: () async {
              if (_regionModel == null) return [];
              var states = await RegionService.getStates(
                regionId: _regionModel?.uid ?? '',
              );
              return states;
            },
            itemAsString: (countries) => countries.name,
            onChanged: (selectedState) async {
              _stateModel = selectedState;
              setState(() {});
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: CustomFutureSearchableDropdown<CityModel>(
            label: 'City',
            asyncItems: () async {
              if (_regionModel == null || _stateModel == null) return [];
              var cities = await RegionService.getCities(
                regionId: _regionModel?.uid ?? '',
                stateId: _stateModel?.uid ?? '',
              );
              return cities;
            },
            itemAsString: (cities) => cities.name,
            onChanged: (selectedCity) async {
              _cityModel = selectedCity;
              setState(() {});
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Postal Code',
            controller: _companyZipController,
            hintText: 'Enter Postal Code',
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Address',
            controller: _companyAddressController,
            hintText: 'Enter Address',
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        List<FileModel> attachments = [];

        if (_selectedAttachments.isNotEmpty) {
          List<String> urls = await StorageService.uploadFilesInBatch(
            files: _selectedAttachments,
            folder: StorageFolder.leadAttachments,
          );

          for (var i = 0; i < _selectedAttachments.length; i++) {
            var file = _selectedAttachments[i];
            var mimeType = lookupMimeType(file.path) ?? '';

            attachments.add(
              FileModel(
                name: path.basename(file.path),
                extension: path.extension(file.path).replaceAll('.', ''),
                size: file.lengthSync(),
                url: urls[i],
                mimeType: mimeType,
              ),
            );
          }
        }

        final workflow = await EmployeeService.getUserWorkflow();

        ClientModel clientModel = ClientModel(
          clientName: '',
          email: '',
          password: '',
          mobileNumber: '',
          loginAllowed: false,
          receiveEmailNotifications: false,
          companyName: _companyNameController.text.trim(),
          officePhoneNo: _companyMobileController.text,
          officialWebsite: _companyWebsiteController.text.trim(),
          postalCode: _companyZipController.text.trim(),
          companyAddress: _companyAddressController.text.trim(),
          country: _regionModel,
          state: _stateModel,
          city: _cityModel,
          createdBy: await Spdb.getUser(),
          isCompany: true,
        );

        var clientId = await ClientService.createClient(client: clientModel);

        final leadModel = LeadModel(
          salutation: _salutation,
          leadName: _leadNameController.text.trim(),
          leadEmail: _leadEmailController.text.trim(),
          leadSource: _selectedLeadSource!,
          leadCategory: _selectedLeadCategory?.uid ?? '',
          leadPriority: _selectedLeadPriority?.uid ?? '',
          leadValue: double.tryParse(_leadValueController.text) ?? 0.0,
          allowFollowUp: _allowFollowUp,
          leadStatus: _leadStatusModel?.uid ?? '',
          notes: _notesController.text.trim(),
          attachments: attachments,
          companyName: _companyNameController.text.trim(),
          companyWebsite: _companyWebsiteController.text.trim(),
          companyMobile: _companyMobileController.text.trim(),
          companyZipCode: _companyZipController.text.trim(),
          companyAddress: _companyAddressController.text.trim(),
          companyCountry: _regionModel,
          companyState: _stateModel,
          companyCity: _cityModel,
          createdBy: await Spdb.getUser(),
          workflow: workflow,
          clientId: clientId,
        );

        await LeadService.createLead(lead: leadModel);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);
        FlushBar.show(context, 'Lead created successfully', isSuccess: true);
      } catch (e, st) {
        debugPrint("$e, $st");
        await ErrorService.recordError(e, st);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        FlushBar.show(context, e.toString(), isSuccess: false);
      }
    }
  }
}
