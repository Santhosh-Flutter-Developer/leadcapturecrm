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

class DealEdit extends StatefulWidget {
  final String uid;
  const DealEdit({super.key, required this.uid});

  @override
  State<DealEdit> createState() => _DealEditState();
}

class _DealEditState extends State<DealEdit> {
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
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyZipController = TextEditingController();

  bool _allowFollowUp = true;
  bool _showCompanyDetails = false;

  late Future _future;
  late DealModel _dealModel;

  List<DealStatusModel> _dealStatus = [];
  DealStatusModel? _dealStatusModel;
  List<RegionModel> _regionsList = [];
  List<StateModel> _statesList = [];
  List<CityModel> _citiesList = [];
  RegionModel? _regionModel;
  StateModel? _stateModel;
  CityModel? _cityModel;
  final List<File> _selectedAttachments = [];
  List<FileModel> _uploadedAttachments = [];

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future<void> _init() async {
    try {
      _dealModel = await DealService.getDeal(uid: widget.uid);

      _dealNameController.text = _dealModel.dealName;
      _dealEmailController.text = _dealModel.dealEmail;
      _dealValueController.text = _dealModel.dealValue.toString();
      _notesController.text = _dealModel.notes;
      _companyNameController.text = _dealModel.companyName ?? '';
      _companyWebsiteController.text = _dealModel.companyWebsite ?? '';
      _companyMobileController.text = _dealModel.companyMobile ?? '';
      _companyAddressController.text = _dealModel.companyAddress ?? '';
      _companyZipController.text = _dealModel.companyZipCode ?? '';

      _regionModel = _dealModel.companyCountry;
      _stateModel = _dealModel.companyState;
      _cityModel = _dealModel.companyCity;

      if (_dealModel.dealStatus != null && _dealModel.dealStatus!.isNotEmpty) {
        _dealStatusModel = await DealStatusService.getDealStatus(
          uid: _dealModel.dealStatus!,
        );
      } else {
        _dealStatusModel = null;
      }

      _allowFollowUp = _dealModel.allowFollowUp;
      _uploadedAttachments = _dealModel.attachments;

      _dealStatus = await DealStatusService.getAllDealStatus();
      _regionsList = await RegionService.getCountries();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
  }

  @override
  void dispose() {
    _dealNameController.dispose();
    _dealEmailController.dispose();
    _dealValueController.dispose();
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
                    title: "Update Deals",
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
          isEdit: true,
        ),
      ),
    );
  }

  Widget _buildDealDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double spacing = 16;
    const double minColumnWidth = 220;

    final bool canGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + spacing * (gridCounts - 1));
    final double itemWidth = canGrid
        ? (currentWidth - spacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: spacing,
      runSpacing: 8,
      children: [
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Deal Name',
            controller: _dealNameController,
            hintText: 'Enter Deal Name',
            isRequired: true,
            valid: (input) =>
                input == null || input.isEmpty ? 'Deal Name is required' : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: const FormFields(
            label: 'Deal Email',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Deal Status',
            initialItem: _dealStatusModel?.name,
            items: _dealStatus.map((e) => e.name).toList(),
            onChanged: (value) {
              _dealStatusModel = _dealStatus.firstWhere(
                (element) => element.name == value,
              );
            },
            validator: (value) => value == null ? "* Required" : null,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Deal Value (₹)',
            controller: _dealValueController,
            hintText: 'Enter Value',
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Allow Follow Up',
            items: const ['Yes', 'No'],
            initialItem: _allowFollowUp ? 'Yes' : 'No',
            onChanged: (value) =>
                _allowFollowUp = value == 'Yes' ? true : false,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Notes',
            controller: _notesController,
            hintText: 'Enter notes...',
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double spacing = 16;
    const double minColumnWidth = 220;

    final bool canGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + spacing * (gridCounts - 1));
    final double itemWidth = canGrid
        ? (currentWidth - spacing * (gridCounts - 1)) / gridCounts
        : currentWidth;

    return Wrap(
      spacing: spacing,
      runSpacing: 8,
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
            hintText: 'Enter Website',
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormFields(
            label: 'Mobile',
            controller: _companyMobileController,
            hintText: 'Enter Mobile',
            keyboardType: TextInputType.phone,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'Country',
            initialItem: _regionsList.any((e) => e.name == _regionModel?.name)
                ? _regionModel?.name
                : null,
            items: _regionsList.map((e) => e.name).toList(),
            onChanged: (value) async {
              _regionModel = _regionsList.firstWhere((e) => e.name == value);
              _statesList = await RegionService.getStates(
                regionId: _regionModel?.uid ?? '',
              );
              setState(() {});
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'State',
            initialItem: _statesList.any((e) => e.name == _stateModel?.name)
                ? _stateModel?.name
                : null,
            items: _statesList.map((e) => e.name).toList(),
            onChanged: (value) async {
              _stateModel = _statesList.firstWhere((e) => e.name == value);
              _citiesList = await RegionService.getCities(
                regionId: _regionModel?.uid ?? '',
                stateId: _stateModel?.uid ?? '',
              );
              setState(() {});
            },
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: FormDropdownSearch(
            label: 'City',
            initialItem: _citiesList.any((e) => e.name == _cityModel?.name)
                ? _cityModel?.name
                : null,
            items: _citiesList.map((e) => e.name).toList(),
            onChanged: (value) async {
              _cityModel = _citiesList.firstWhere((e) => e.name == value);
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

  Widget _buildAttachmentDetails(BoxConstraints constraints, int gridCounts) {
    final double currentWidth = constraints.maxWidth;
    const double spacing = 16;
    const double minColumnWidth = 220;

    final bool canGrid =
        currentWidth >=
        (minColumnWidth * gridCounts + spacing * (gridCounts - 1));
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        List<FileModel> attachments = _uploadedAttachments;
        if (_selectedAttachments.isNotEmpty) {
          List<String> urls = await StorageService.uploadFilesInBatch(
            files: _selectedAttachments,
            folder: StorageFolder.dealAttachments,
          );

          for (var i = 0; i < _selectedAttachments.length; i++) {
            var j = _selectedAttachments[i];
            var mimeType = lookupMimeType(j.path) ?? '';

            attachments.add(
              FileModel(
                name: path.basename(j.path),
                extension: path.basename(j.path).split('.').last,
                size: j.lengthSync(),
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

        var clientId = _dealModel.clientId;
        if (clientId != null) {
          await ClientService.editClient(client: clientModel, uid: clientId);
        } else {
          clientId = await ClientService.createClient(client: clientModel);
        }

        final DealModel dealModel = DealModel(
          dealName: _dealNameController.text.trim(),
          dealEmail: _dealEmailController.text.trim(),
          dealValue: double.tryParse(_dealValueController.text) ?? 0.0,
          allowFollowUp: _allowFollowUp,
          dealStatus: _dealStatusModel?.uid,
          notes: _notesController.text.trim(),
          attachments: attachments,
          companyName: _companyNameController.text.trim(),
          companyWebsite: _companyWebsiteController.text.trim(),
          companyMobile: _companyMobileController.text.trim(),
          companyAddress: _companyAddressController.text.trim(),
          companyZipCode: _companyZipController.text.trim(),
          companyCountry: _regionModel,
          companyState: _stateModel,
          companyCity: _cityModel,
          workFlow: workflow,
          clientId: clientId,
          createdBy: await Spdb.getUser(),
        );

        await DealService.updateDeal(uid: widget.uid, deal: dealModel);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true);
        FlushBar.show(context, 'Deal updated successfully!', isSuccess: true);
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
