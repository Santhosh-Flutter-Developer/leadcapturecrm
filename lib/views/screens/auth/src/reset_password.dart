import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class ResetPassword extends StatefulWidget {
  final Map<String, dynamic> emailData;
  const ResetPassword({super.key, required this.emailData});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        await AuthService.resetPassword(
          emailData: widget.emailData,
          newPassword: _newPassword.text.trim(),
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        FlushBar.show(
          context,
          "Password reset successfully! Please login again.",
          isSuccess: true,
        );

        if (widget.emailData['email'] != null) {
          await EmailService.sendEmail(
            to: [widget.emailData['email'].toString().trim()],
            toName: ["${widget.emailData['name'] ?? 'User'}"],
            subject: "Password Reset Successfully",
            message: EmailTemplates.successResetPassword,
          );
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          Navigate.routeReplace(context, const Login());
        });
      } catch (e, st) {
        await ErrorService.recordError(e, st);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        FlushBar.show(
          context,
          "Something went wrong. Try again.",
          isSuccess: false,
          error: e,
          stackTrace: st,
        );
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
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blueGrey.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          ImageAssets.logoTransparent,
                          height: 55,
                          width: 55,
                        ),
                      ),
                      const Divider(height: 30, thickness: 1.2),
                      const SizedBox(height: 10),
                      Text(
                        "Reset Password",
                        style: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1F23),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Enter your new password below and confirm it to complete the reset process.",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.grey700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        "New Password",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormFields(
                        controller: _newPassword,
                        valid: (value) => Validation.passwordValidation(
                          input: value ?? '',
                          isReq: true,
                        ),
                        keyboardType: TextInputType.visiblePassword,
                        hintText: "••••••••",
                        obsecureText: !_passwordVisible,
                        prefixIcon: const Icon(Iconsax.lock, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _passwordVisible = !_passwordVisible;
                          }),
                          icon: Icon(
                            _passwordVisible ? Iconsax.eye : Iconsax.eye_slash,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Confirm Password",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormFields(
                        controller: _confirmPassword,
                        valid: (value) {
                          if ((value ?? '').isEmpty) {
                            return "Confirm password is required";
                          } else if (value != _newPassword.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.visiblePassword,
                        hintText: "••••••••",
                        obsecureText: !_confirmVisible,
                        prefixIcon: const Icon(Iconsax.lock, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _confirmVisible = !_confirmVisible;
                          }),
                          icon: Icon(
                            _confirmVisible ? Iconsax.eye : Iconsax.eye_slash,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0052D4),
                                Color(0xFF4364F7),
                                Color(0xFF6FB1FC),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0056D2,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.transparent,
                              shadowColor: AppColors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Reset Password",
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: AppColors.white,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              Navigate.routeReplace(context, const Login()),
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
}
