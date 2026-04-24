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

class LeadEdit extends StatefulWidget {
  final String uid;
  const LeadEdit({super.key, required this.uid});

  @override
  State<LeadEdit> createState() => _LeadEditState();
}

class _LeadEditState extends State<LeadEdit> {
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
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyZipController = TextEditingController();

  // String? _salutation;
  // final bool _allowFollowUp = true;

  bool _showCompanyDetails = false;
  bool _companyrefresh = false;
  late Future _future;

  List<LeadCategoryModel> _leadCategories = [];
  List<LeadPriorityModel> _leadPriorities = [];
  List<LeadStatusModel> _leadStatus = [];
  List<ClientModel> _clients = [];
  ClientModel? _selectedclient;
  LeadCategoryModel? _leadCategory;
  LeadPriorityModel? _leadPriority;
  LeadStatusModel? _leadStatusModel;

  RegionModel? _regionModel;
  StateModel? _stateModel;
  CityModel? _cityModel;

  late LeadModel _leadModel;
  final List<File> _selectedAttachments = [];
  List<FileModel> _uploadedAttachments = [];

  final List<LeadSourceModel> _leadSource = [];
  LeadSourceModel? _selectedLeadSource;

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future<void> _init() async {
    try {
      _leadModel = await LeadService.getLead(uid: widget.uid);

      _leadNameController.text = _leadModel.leadName;
      _leadEmailController.text = _leadModel.leadEmail;
      _leadValueController.text = _leadModel.leadValue.toString();
      _notesController.text = _leadModel.notes;
      _companyNameController.text = _leadModel.companyName ?? '';
      _companyWebsiteController.text = _leadModel.companyWebsite ?? '';
      _companyMobileController.text = _leadModel.companyMobile ?? '';
      _companyAddressController.text = _leadModel.companyAddress ?? '';
      _companyZipController.text = _leadModel.companyZipCode ?? '';
      // _salutation = _leadModel.salutation;
      _selectedLeadSource = _leadModel.leadSource;
      _regionModel = _leadModel.companyCountry;
      _stateModel = _leadModel.companyState;
      _cityModel = _leadModel.companyCity;

      if (_leadModel.leadCategory.isNotEmpty) {
        _leadCategory = await LeadCategoryService.getLeadCategory(
          uid: _leadModel.leadCategory,
        );
      }

      if (_leadModel.leadStatus.isNotEmpty) {
        _leadStatusModel = await LeadStatusService.getLeadStatus(
          uid: _leadModel.leadStatus,
        );
      }

      if (_leadModel.leadPriority.isNotEmpty) {
        _leadPriority = await LeadPriorityService.getLeadPriority(
          uid: _leadModel.leadPriority,
        );
      }

      // _allowFollowUp = _leadModel.allowFollowUp;
      _uploadedAttachments = _leadModel.attachments;

      _leadCategories.clear();
      _leadPriorities.clear();
      _leadStatus.clear();
      _clients.clear();

      _leadCategories = await LeadCategoryService.getAllLeadCategories();
      _leadPriorities = await LeadPriorityService.getAllLeadPriority();
      _leadStatus = await LeadStatusService.getAllLeadStatus();
      _clients = (await ClientService.getAllClients())
          .where((c) => c.isCompany && (c.companyName?.isNotEmpty ?? false))
          .toList();
      _selectedclient= await ClientService.getClient(uid: _leadModel.clientId ?? '');
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
                    title: "Update Lead",
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
          isEdit: true,
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
          children: [..._selectedAttachments, ..._uploadedAttachments].map((
            file,
          ) {
            return Chip(
              label: file is File
                  ? Text(
                      path.basename(file.path),
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : file is FileModel
                  ? Text(
                      file.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : const SizedBox(),
              onDeleted: () async {
                if (file is FileModel) {
                  try {
                    futureLoading(context);
                    await StorageService.deleteImage(file.url);
                    _uploadedAttachments.remove(file);
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (e, st) {
                    await ErrorService.recordError(e, st);
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    FlushBar.show(context, e.toString(), isSuccess: false);
                  }
                } else {
                  _selectedAttachments.remove(file);
                }

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
        // SizedBox(
        //   width: itemWidth,
        //   child: FormDropdownSearch(
        //     label: 'Salutation',
        //     initialItem: _salutation,
        //     items: const ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
        //     onChanged: (value) => _salutation = value as String?,
        //   ),
        // ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Lead Name',
            controller: _leadNameController,
            hintText: 'e.g. John Doe',
            isRequired: true,
            valid: (input) =>
                input == null || input.isEmpty ? 'Lead Name is required' : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Lead Email',
            controller: _leadEmailController,
            hintText: 'e.g. johndoe@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            initialItem: _selectedLeadSource?.name,
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
            initialItem: _leadCategory?.name,
            items: _leadCategories.map((e) => e.name).toList(),
            onChanged: (value) {
              _leadCategory = _leadCategories.firstWhere(
                (element) => element.name == value,
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
            initialItem: _leadPriority?.name,
            items: _leadPriorities.map((e) => e.name).toList(),
            onChanged: (value) {
              _leadPriority = _leadPriorities.firstWhere(
                (element) => element.name == value,
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
        // SizedBox(
        //   width: itemWidth,
        //   child: FormDropdownSearch(
        //     label: 'Allow Follow Up',
        //     items: const ['Yes', 'No'],
        //     initialItem: _allowFollowUp ? 'Yes' : 'No',
        //     onChanged: (value) =>
        //         _allowFollowUp = value == 'Yes' ? true : false,
        //     validator: (value) => value == null ? "* Required" : null,
        //   ),
        // ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Status',
            initialItem: _leadStatusModel?.name,
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
        // SizedBox(
        //   width: itemWidth,
        //   child: FormFields(
        //     label: 'Company Name',
        //     controller: _companyNameController,
        //     hintText: 'Enter Company Name',
        //   ),
        // ),
        _companyrefresh == true
            ? SizedBox()
            : 
        SizedBox(
          width: itemWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FormDropdownSearch(
                  label: 'Company Name',
                  initialItem: _selectedclient?.companyName,
                  items: _clients.map((e) => e.companyName).toList(),
                  onChanged: (value) {
                    _selectedclient = _clients.cast<ClientModel?>().firstWhere(
                      (cat) => cat?.companyName == value,
                      orElse: () => null,
                    );
                    _companyNameController.text =
                        _selectedclient?.companyName ?? '';
                    _companyWebsiteController.text =
                        _selectedclient?.officialWebsite ?? '';
                    _companyMobileController.text =
                        _selectedclient?.officePhoneNo ?? "";
                    _regionModel = _selectedclient?.country;
                    _stateModel = _selectedclient?.state;
                    _cityModel = _selectedclient?.city;
                    _companyZipController.text =
                        _selectedclient?.postalCode ?? "";
                    _companyAddressController.text =
                        _selectedclient?.companyAddress ?? "";
                  },
                  validator: (value) => value == null ? "* Required" : null,
                ),
              ),
              SizedBox(width: 8.0),
              InkWell(
                onTap: () async {
                final form = CompanyCreate();
                        dynamic val;
                        if (kIsMobile) {
                          val = await Sheet.showSheet(context, widget: form);
                        } else {
                          val = await GeneralDialog.showRTLSheet(context, form);
                        }
                        if (val is Map && val["status"] == true) {
                          setState(() {
                            _companyrefresh = true;
                          });
                          _clients = await ClientService.getAllClients();
                          if (val["company"] != null) {
                            _selectedclient = val["company"];
                            _companyWebsiteController.text =
                                _selectedclient?.officialWebsite ?? '';
                            _companyMobileController.text =
                                _selectedclient?.officePhoneNo ?? "";
                            _regionModel = _selectedclient?.country;
                            _stateModel = _selectedclient?.state;
                            _cityModel = _selectedclient?.city;
                            _companyZipController.text =
                                _selectedclient?.postalCode ?? "";
                            _companyAddressController.text =
                                _selectedclient?.companyAddress ?? "";
                          }
                          setState(() {
                            _companyrefresh = false;
                          });
                        }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Icon(Icons.add, color: AppColors.white),
                  ),
                ),
              ),
            ],
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
            initialValue: _regionModel,
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
            initialValue: _stateModel,
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
            initialValue: _cityModel,
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        List<FileModel> attachments = _uploadedAttachments;
        if (_selectedAttachments.isNotEmpty) {
          List<String> urls = await StorageService.uploadFilesInBatch(
            files: _selectedAttachments,
            folder: StorageFolder.leadAttachments,
          );

          for (var i = 0; i < _selectedAttachments.length; i++) {
            var j = _selectedAttachments[i];
            var mimeType = lookupMimeType(j.path) ?? '';

            FileModel file = FileModel(
              name: path.basename(j.path),
              extension: path.basename(j.path).split('.').last,
              size: j.lengthSync(),
              url: urls[i],
              mimeType: mimeType,
            );
            attachments.add(file);
          }
        }

        final workflow = await EmployeeService.getUserWorkflow();

        // ClientModel clientModel = ClientModel(
        //   clientName: '',
        //   email: '',
        //   password: '',
        //   mobileNumber: '',
        //   loginAllowed: false,
        //   receiveEmailNotifications: false,
        //   companyName: _companyNameController.text.trim(),
        //   officePhoneNo: _companyMobileController.text,
        //   officialWebsite: _companyWebsiteController.text.trim(),
        //   postalCode: _companyZipController.text.trim(),
        //   companyAddress: _companyAddressController.text.trim(),
        //   country: _regionModel,
        //   state: _stateModel,
        //   city: _cityModel,
        //   createdBy: await Spdb.getUser(),
        //   isCompany: true,
        // );

        // var clientId = _leadModel.clientId;
        // if (clientId != null) {
        //   await ClientService.editClient(client: clientModel, uid: clientId);
        // } else {
        //   clientId = await ClientService.createClient(client: clientModel);
        // }

        LeadModel leadModel = LeadModel(
          // salutation: _salutation,
          leadName: _leadNameController.text,
          leadEmail: _leadEmailController.text,
          leadSource: _selectedLeadSource!,
          leadCategory: _leadCategory?.uid ?? '',
          leadPriority: _leadPriority?.uid ?? '',
          leadValue: double.parse(_leadValueController.text),
          // allowFollowUp: _allowFollowUp,
          leadStatus: _leadStatusModel?.uid ?? '',
          notes: _notesController.text,
          attachments: attachments,
          companyName: _selectedclient?.companyName ?? _companyNameController.text,
          companyWebsite: _companyWebsiteController.text,
          companyMobile: _companyMobileController.text,
          companyZipCode: _companyZipController.text,
          companyAddress: _companyAddressController.text,
          companyCountry: _regionModel,
          companyState: _stateModel,
          companyCity: _cityModel,
          workflow: workflow,
          clientId: _selectedclient?.uid,
          createdBy: await Spdb.getUser(),
        );

        await LeadService.updateLead(uid: widget.uid, lead: leadModel);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);

        FlushBar.show(context, 'Lead updated successfully', isSuccess: true);
      } catch (e, st) {
        await ErrorService.recordError(e, st);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        FlushBar.show(context, e.toString(), isSuccess: false);
      }
    }
  }
}
