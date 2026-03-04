import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leadcapture/services/firebase/src/auth_service.dart';
import 'package:leadcapture/theme/src/app_colors.dart';
import 'package:leadcapture/utils/src/assets.dart';
import 'package:leadcapture/utils/src/validation.dart';
import 'package:leadcapture/views/ui/src/flush_bar.dart';
import 'package:leadcapture/views/ui/src/form_fields.dart';
import 'package:leadcapture/views/ui/src/loading.dart';

class CompanyRegistration extends StatefulWidget {
  const CompanyRegistration({super.key});

  @override
  State<CompanyRegistration> createState() => _CompanyRegistrationState();
}

class _CompanyRegistrationState extends State<CompanyRegistration> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _companyEmail = TextEditingController();
  final TextEditingController _adminName = TextEditingController();
  final TextEditingController _adminEmail = TextEditingController();
  final TextEditingController _password = TextEditingController();

  File? _logo;
  bool _passwordVisible = false;

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) setState(() => _logo = File(image.path));
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        var result = await AuthService.registerCompany(
          name: _companyName.text.trim(),
          adminEmail: _adminEmail.text.trim(),
          adminName: _adminName.text.trim(),
          password: _password.text.trim(),
          logo: _logo,
        );

        if (Navigator.canPop(context)) Navigator.pop(context);

        if (result["status"]) {
          FlushBar.show(context, result["message"], isSuccess: true);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          FlushBar.show(context, result['error'], isSuccess: false);
        }
      } catch (e) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        FlushBar.show(context, e.toString(), isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 25),

                      // 1. Logo Picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: _logo != null
                              ? FileImage(_logo!)
                              : null,
                          child: _logo == null
                              ? const Icon(
                                  Iconsax.camera,
                                  color: Colors.blueAccent,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Company Details Section
                      _sectionTitle("Company Details"),
                      _customField(
                        "Company Name",
                        _companyName,
                        Iconsax.box,
                        false,
                      ),
                      _customField(
                        "Business Email",
                        _companyEmail,
                        Iconsax.sms,
                        false,
                      ),

                      const SizedBox(height: 10),

                      // 3. Admin Setup Section
                      _sectionTitle("Super Admin Setup"),
                      _customField(
                        "Full Name",
                        _adminName,
                        Iconsax.user,
                        false,
                      ),
                      _customField(
                        "Admin Email",
                        _adminEmail,
                        Iconsax.sms,
                        false,
                      ),

                      // Password Field
                      _passwordField(),

                      const SizedBox(height: 35),

                      // 4. Submit Button
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Iconsax.login, size: 18),
                          label: Text(
                            "Back to Login",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }

  Widget _customField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isEmail,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          FormFields(
            controller: controller,
            hintText: "Enter $label",
            prefixIcon: Icon(icon, size: 20),
            valid: (value) => Validation.commonValidation(
              input: value ?? '',
              isReq: true,
              label: label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Admin Password",
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        FormFields(
          controller: _password,
          obsecureText: !_passwordVisible,
          hintText: "Create password",
          prefixIcon: const Icon(Iconsax.lock, size: 20),
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
            icon: Icon(
              _passwordVisible ? Iconsax.eye : Iconsax.eye_slash,
              size: 20,
            ),
          ),
          valid: (value) => Validation.commonValidation(
            input: value ?? '',
            isReq: true,
            label: "Password",
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(ImageAssets.logoTransparent, height: 45, width: 45),
            // IconButton(
            //   onPressed: () => Navigator.pop(context),
            //   icon: const Icon(Icons.close),
            // ),
          ],
        ),
        const Divider(height: 30, thickness: 1.2),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Register Company",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1F23),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
