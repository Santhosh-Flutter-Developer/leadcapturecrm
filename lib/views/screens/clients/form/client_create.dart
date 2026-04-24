import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/constants/constants.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/utils/utils.dart';

class ContactCreate extends StatefulWidget {
  const ContactCreate({super.key});

  @override
  State<ContactCreate> createState() => _ContactCreateState();
}

class _ContactCreateState extends State<ContactCreate> {
  final _formKey = GlobalKey<FormState>();

  final _clientName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _mobile = TextEditingController();

  File? _profileImage;
  String? _salutation;
  String? _gender;
  String? _language;

  final bool _loginAllowed = true;
  final bool _emailNotify = true;
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FormWidgets.buildHeader(
                context: context,
                title: "Create Contact",
              ),

              _buildContactDetails(),

              const SizedBox(height: 24),

              _buildProfileImageSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FormWidgets.buildBottomBar(
        context: context,
        onSubmit: _submit,
        isEdit: false,
      ),
    );
  }

  Widget _buildContactDetails() {
    return _section(
      "Contact Details",
      Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormDropdownSearch(
                    label: "Salutation",
                    items: const ["Mr.", "Mrs.", "Ms.", "Dr."],
                    onChanged: (v) => _salutation = v,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(
                    label: "Name",
                    controller: _clientName,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(
                    label: "Email",
                    controller: _email,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(
                    label: "Password",
                    controller: _password,
                    obsecureText: !_passwordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Iconsax.eye : Iconsax.eye_slash,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormFields(label: "Mobile", controller: _mobile),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormDropdownSearch(
                    label: "Gender",
                    items: const ["Male", "Female", "Other"],
                    onChanged: (v) => _gender = v,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormDropdownSearch(
                    label: "Language",
                    items: AppStrings.spokenLanguages,
                    onChanged: (v) => _language = v,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return _section(
      "Profile Picture",
      imagePickerWidget(
        context: context,
        image: _profileImage,
        onChanged: (file) => setState(() => _profileImage = file),
        label: "Upload Profile",
      ),
    );
  }

  Widget imagePickerWidget({
    required BuildContext context,
    required File? image,
    required Function(File) onChanged,
    required String label,
  }) {
    return image != null
        ? Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  image,
                  height: 140,
                  width: 140,
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
                    if (result != null) onChanged(result);
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
          )
        : GestureDetector(
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
              if (result != null) onChanged(result);
            },
            child: DottedBorder(
              child: Container(
                height: 140,
                width: 140,
                decoration: const BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.gallery, color: AppColors.grey700),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _section(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      futureLoading(context);

      final imageUrl = _profileImage == null
          ? null
          : await StorageService.uploadFile(
              file: _profileImage!,
              folder: StorageFolder.clientPhotos,
            );

      final client = ClientModel(
        salutation: _salutation,
        clientName: _clientName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        mobileNumber: _mobile.text,
        gender: _gender,
        changeLanguage: _language,
        loginAllowed: _loginAllowed,
        receiveEmailNotifications: _emailNotify,
        profilePictureUrl: imageUrl,
        createdBy: await Spdb.getUser(),
        isCompany: false,
      );

      await ClientService.createClient(client: client);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pop(context, true);
      FlushBar.show(context, "Contact created", isSuccess: true);
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

class CompanyCreate extends StatefulWidget {
  const CompanyCreate({super.key});

  @override
  State<CompanyCreate> createState() => _CompanyCreateState();
}

class _CompanyCreateState extends State<CompanyCreate> {
  final _formKey = GlobalKey<FormState>();

  final _companyName = TextEditingController();
  final _website = TextEditingController();
  final _gst = TextEditingController();
  final _phone = TextEditingController();
  final _postal = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();

  File? _logo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FormWidgets.buildHeader(
                context: context,
                title: "Create Company",
              ),

              _buildCompanyDetails(),

              _buildLogoSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FormWidgets.buildBottomBar(
        context: context,
        onSubmit: _submit,
        isEdit: false,
      ),
    );
  }

  Widget _buildCompanyDetails() {
    return _section(
      "Company Information",
      Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormFields(
                    label: "Company Name",
                    controller: _companyName,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(label: "Website", controller: _website),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(label: "GST / VAT", controller: _gst),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(label: "Office Phone", controller: _phone),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormFields(
                    label: "Postal Code",
                    controller: _postal,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(
                    label: "Company Address",
                    controller: _address,
                    maxLines: 2,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormFields(
                    label: "Note",
                    controller: _note,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return _section(
      "Company Logo",
      imagePickerWidget(
        context: context,
        image: _logo,
        onChanged: (file) => setState(() => _logo = file),
        label: "Upload Logo",
      ),
    );
  }

  Widget imagePickerWidget({
    required BuildContext context,
    required File? image,
    required Function(File) onChanged,
    required String label,
  }) {
    return image != null
        ? Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  image,
                  height: 140,
                  width: 140,
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
                    if (result != null) onChanged(result);
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
          )
        : GestureDetector(
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
              if (result != null) onChanged(result);
            },
            child: DottedBorder(
              child: Container(
                height: 140,
                width: 140,
                decoration: const BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.gallery, color: AppColors.grey700),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _section(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      futureLoading(context);

      final logoUrl = _logo == null
          ? null
          : await StorageService.uploadFile(
              file: _logo!,
              folder: StorageFolder.clientCompanyLogos,
            );

      final company = ClientModel(
        companyName: _companyName.text.trim(),
        officialWebsite: _website.text.trim(),
        gstVatNumber: _gst.text.trim(),
        officePhoneNo: _phone.text.trim(),
        postalCode: _postal.text.trim(),
        companyAddress: _address.text.trim(),
        notes: _note.text.trim(),
        companyLogoUrl: logoUrl,
        createdBy: await Spdb.getUser(),
        isCompany: true,
      );

      await ClientService.createClient(client: company);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
     Navigator.pop(context, {
        "status":true,
        "company":company});
      FlushBar.show(context, "Company created", isSuccess: true);
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
