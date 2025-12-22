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

class DealCreate extends StatefulWidget {
  final bool? isFromLead;
  final DealModel? prefillDeal;

  const DealCreate({super.key, this.isFromLead, this.prefillDeal});

  @override
  State<DealCreate> createState() => _DealCreateState();
}

class _DealCreateState extends State<DealCreate> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _dealNameController = TextEditingController();
  final TextEditingController _dealEmailController = TextEditingController();

  final TextEditingController _dealValueController = TextEditingController();
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

  bool _showCompanyDetails = false;
  late Future _future;
  DealStatusModel? _dealStatusModel;

  bool _allowFollowUp = true;

  final List<DealStatusModel> _dealStatus = [];
  List<RegionModel> _regionsList = [];
  List<StateModel> _statesList = [];
  List<CityModel> _citiesList = [];
  RegionModel? _regionModel;
  StateModel? _stateModel;
  CityModel? _cityModel;

  final List<File> _selectedAttachments = [];

  @override
  void initState() {
    _future = _init();
    super.initState();

    if (widget.prefillDeal != null) {
      final deal = widget.prefillDeal!;

      _dealNameController.text = deal.dealName;
      _dealEmailController.text = deal.dealEmail;
      _dealValueController.text = deal.dealValue.toString();
      _notesController.text = deal.notes;

      _companyNameController.text = deal.companyName ?? '';
      _companyWebsiteController.text = deal.companyWebsite ?? '';
      _companyMobileController.text = deal.companyMobile ?? '';
      _companyAddressController.text = deal.companyAddress ?? '';
      _companyZipController.text = deal.companyZipCode ?? '';

      _allowFollowUp = deal.allowFollowUp;
      _regionModel = deal.companyCountry;
      _stateModel = deal.companyState;
      _cityModel = deal.companyCity;

      if (deal.attachments.isNotEmpty) {}
    }
  }

  Future<void> _init() async {
    try {
      _regionsList = await RegionService.getCountries();

      _dealStatus.addAll(await DealStatusService.getAllDealStatus());

      if (widget.prefillDeal?.dealStatus != null) {
        _dealStatusModel = await DealStatusService.getDealStatus(
          uid: widget.prefillDeal!.dealStatus!,
        );
      }

      setState(() {});
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
  }

  @override
  void dispose() {
    _dealNameController.dispose();
    _dealValueController.dispose();
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
                    title: "Create Deals",
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildSectionCard(
                              "Deal Details",
                              LayoutBuilder(
                                builder: (context, constraints) =>
                                    _buildDealDetails(constraints, 3),
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

  Widget _buildDealDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double spacing = 16.0;
    const double minWidth = 220.0;
    final bool canGrid =
        currentWidth >= (minWidth * gridCounts + spacing * (gridCounts - 1));
    final double itemWidth = canGrid
        ? (currentWidth - spacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: spacing,
      runSpacing: 10,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Deal Name',
            controller: _dealNameController,
            isRequired: true,
            hintText: 'e.g. New Business Deal',
            valid: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Deal Email',
            controller: _dealEmailController,
            isRequired: true,
            hintText: 'e.g. email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Deal Value (₹)',
            controller: _dealValueController,
            keyboardType: TextInputType.number,
            hintText: 'Enter amount',
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
            items: _dealStatus.map((e) => e.name).toList(),
            initialItem: _dealStatusModel?.name,
            onChanged: (value) {
              setState(() {
                _dealStatusModel = _dealStatus.firstWhere(
                  (element) => element.name == value,
                );
              });
            },
            // validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Note',
            controller: _notesController,
            hintText: 'Enter note...',
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double spacing = 16.0;
    const double minWidth = 220.0;
    final bool canGrid =
        currentWidth >= (minWidth * gridCounts + spacing * (gridCounts - 1));
    final double itemWidth = canGrid
        ? (currentWidth - spacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: spacing,
      runSpacing: 10,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Company Name',
            controller: _companyNameController,
            hintText: 'Enter company name',
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Website',
            controller: _companyWebsiteController,
            hintText: 'Enter website URL',
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Mobile',
            controller: _companyMobileController,
            hintText: 'Enter mobile number',
            keyboardType: TextInputType.phone,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Country',
            items: _regionsList.map((e) => e.name).toList(),
            onChanged: (value) async {
              _regionModel = _regionsList.firstWhere((r) => r.name == value);
              if (_regionModel != null) {
                _statesList = await RegionService.getStates(
                  regionId: _regionModel!.uid!,
                );
                setState(() {});
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'State',
            items: _statesList.map((e) => e.name).toList(),
            onChanged: (value) async {
              _stateModel = _statesList.firstWhere((s) => s.name == value);
              if (_regionModel != null && _stateModel != null) {
                _citiesList = await RegionService.getCities(
                  regionId: _regionModel!.uid!,
                  stateId: _stateModel!.uid!,
                );
                setState(() {});
              }
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'City',
            items: _citiesList.map((e) => e.name).toList(),
            onChanged: (value) =>
                _cityModel = _citiesList.firstWhere((c) => c.name == value),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Postal Code',
            controller: _companyZipController,
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Address',
            controller: _companyAddressController,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double spacing = 16.0;
    const double minWidth = 220.0;
    final bool canGrid =
        currentWidth >= (minWidth * gridCounts + spacing * (gridCounts - 1));
    final double itemWidth = canGrid
        ? (currentWidth - spacing * (gridCounts - 1)) / gridCounts
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
              if (files != null && files.isNotEmpty) {
                _selectedAttachments.addAll(files);
                setState(() {});
              }
            },
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        List<FileModel> attachments = [];

        if (_selectedAttachments.isNotEmpty) {
          List<String> urls = await StorageService.uploadFilesInBatch(
            files: _selectedAttachments,
            folder: StorageFolder.dealAttachments,
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
        );

        var clientId = await ClientService.createClient(client: clientModel);

        final dealModel = DealModel(
          dealName: _dealNameController.text.trim(),
          dealEmail: _dealEmailController.text.trim(),
          dealValue: double.tryParse(_dealValueController.text) ?? 0,
          allowFollowUp: _allowFollowUp,
          dealStatus: _dealStatusModel?.uid,
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
          workFlow: workflow,
          clientId: clientId,
        );

        await DealService.createDeal(deal: dealModel);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);
        FlushBar.show(context, 'Deal created successfully', isSuccess: true);
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
