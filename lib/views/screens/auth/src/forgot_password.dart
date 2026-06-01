import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pinput/pinput.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/constants/constants.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _otp = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _emailVerified = false;
  Map<String, dynamic>? _emailData;
  bool _otpSent = false;
  String? _generatedOtp;
  Timer? _timer;
  int _remainingTime = 0;

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_emailVerified) {
      try {
        futureLoading(context);

        final emailData = await AuthService.checkEmailExists(
          email: _email.text.trim(),
        );
        if (emailData == null) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          FlushBar.show(
            context,
            "Email not found. Please check and try again.",
            isSuccess: false,
          );
          return;
        } else {
          setState(() {
            _emailVerified = true;
            _emailData = emailData;
          });
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } catch (e, st) {
        await ErrorService.recordError(e, st);
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

  /// Send OTP via email
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      futureLoading(context);

      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedOtp = otp;

      final response = await EmailService.sendEmail(
        to: [_email.text.trim()],
        toName: ["${_emailData?['name'] ?? 'User'}"],
        subject: "OTP for Password Reset",
        message: EmailTemplates.otpEmail.replaceAll("{otp_code}", otp),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (response) {
        setState(() {
          _otpSent = true;
          _remainingTime = 120; // 2 minutes
        });
        _startTimer();

        FlushBar.show(context, 'OTP sent successfully to your email.');
      } else {
        FlushBar.show(
          context,
          "Failed to send OTP. Try again.",
          isSuccess: false,
        );
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
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

  /// Timer countdown for OTP expiry
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        timer.cancel();
        setState(() {
          _generatedOtp = null;
        });
      } else {
        setState(() => _remainingTime--);
      }
    });
  }

  /// Verify OTP entered by user
  void _verifyOtp() {
    if (_generatedOtp == null) {
      FlushBar.show(context, "OTP expired. Please resend.", isSuccess: false);
      return;
    }

    if (_otp.text.trim() == _generatedOtp) {
      FlushBar.show(context, "OTP verified successfully!");
      _timer?.cancel();
      Navigate.route(context, ResetPassword(emailData: _emailData ?? {}));
    } else {
      FlushBar.show(
        context,
        "Invalid OTP. Please try again.",
        isSuccess: false,
      );
    }
  }

  /// Resend OTP after cooldown (only after 60s)
  Future<void> _resendOtp() async {
    if (_remainingTime > 60) {
      FlushBar.show(
        context,
        "Please wait before resending OTP.",
        isSuccess: false,
      );
      return;
    }
    await _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    super.dispose();
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
                        "Forgot Password",
                        style: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1F23),
                            ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Email",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormFields(
                        controller: _email,
                        valid: (value) =>
                            Validation.validEmail(input: value, isReq: true),
                        keyboardType: TextInputType.emailAddress,
                        hintText: "example@domain.com",
                        prefixIcon: const Icon(Iconsax.sms, size: 20),
                      ),
                      if (_emailVerified) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "User verified",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      if (_otpSent) ...[
                        Text(
                          "Enter OTP",
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey700,
                              ),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: Pinput(
                            length: 6,
                            controller: _otp,
                            keyboardType: TextInputType.number,
                            defaultPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey400),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Resend and Timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_generatedOtp == null)
                              TextButton(
                                onPressed: _resendOtp,
                                child: Text(
                                  "Resend OTP",
                                  style: Theme.of(context).textTheme.bodySmall!,
                                ),
                              )
                            else
                              Text(
                                "Expires in ${_remainingTime}s",
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
                                      color: AppColors.grey700,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      Container(
                        width: double.infinity,
                        height: 45, // Matched height
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0052D4),
                              Color(0xFF4364F7),
                              Color(0xFF6FB1FC),
                            ],
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
                          onPressed: _emailVerified
                              ? _otpSent
                                    ? _verifyOtp
                                    : _sendOtp
                              : _verifyEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _emailVerified
                                ? _otpSent
                                      ? "Verify OTP"
                                      : "Send OTP"
                                : "Verify User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),

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
}
