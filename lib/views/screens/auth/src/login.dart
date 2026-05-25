import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/app/src/auth_provider.dart';
import 'package:leadcapture/views/screens/auth/src/company_registration.dart';
import 'package:provider/provider.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _passwordVisible = false;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        String input = _email.text.trim();
        bool isAdminLogin = input.contains("@");

        // ─────────────────────────────────────────────
        // LOCATION ENABLE CHECK BEFORE LOGIN
        // ─────────────────────────────────────────────

        if (kIsMobile && !isAdminLogin) {
          // Check GPS service enabled
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

          if (!serviceEnabled) {
            _showLocationDialog(
              icon: Iconsax.gps_slash,
              iconColor: Colors.orange,
              title: 'Enable Location',
              message: 'Please enable your device location to continue login.',
              primaryLabel: 'Open Settings',
              primaryAction: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
            );
            return;
          }

          // Check permission
          LocationPermission permission = await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          // Permission denied
          if (permission == LocationPermission.denied) {
            FlushBar.show(
              context,
              'Location permission is required for login.',
              isSuccess: false,
            );
            return;
          }

          // Permission permanently denied
          if (permission == LocationPermission.deniedForever) {
            _showLocationDialog(
              icon: Iconsax.lock,
              iconColor: Colors.red,
              title: 'Location Permission Required',
              message:
                  'Location permission is permanently denied. '
                  'Please enable it from App Settings.',
              primaryLabel: 'Open App Settings',
              primaryAction: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              },
            );
            return;
          }
        }

        // ─────────────────────────────────────────────
        // LOGIN PROCESS
        // ─────────────────────────────────────────────

        futureLoading(context);

        var result = await AuthService.checkLogin(
          email: isAdminLogin ? input : null,
          employeeId: isAdminLogin ? null : input,
          password: _password.text.trim(),
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (!result["status"]) {
          FlushBar.show(context, result['error'], isSuccess: false);
          return;
        }

        // --- Geofence check (mobile employees only) ---
        if (kIsMobile && !isAdminLogin) {
          final String cid = result["collectionId"];
          final companySnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(cid)
              .get();
          final companyData = companySnap.data();
          if (companyData != null) {
            final lat = (companyData['companyLat'] as num?)?.toDouble();
            final lng = (companyData['companyLng'] as num?)?.toDouble();
            final radius = (companyData['companyRadius'] as num?)?.toDouble();

            if (lat != null && lng != null && radius != null) {
              final checkResult = await LocationService.checkGeofence(
                centerLat: lat,
                centerLng: lng,
                radiusMeters: radius,
              );

              if (checkResult != LocationCheckResult.success) {
                _handleLocationResult(checkResult);
                return;
              }
            }
          }
        }

        // Save session and refresh
        if (isAdminLogin) {
          AdminModel admin = AdminModel.fromMap(
            result["uid"],
            result["adminData"],
          );
          await Spdb.setAdminLogin(
            model: admin,
            cid: result["collectionId"],
            logoUrl: result["companyLogo"],
          );
        } else {
          EmployeeModel employee = EmployeeModel.fromMap(
            result["uid"],
            result["userData"],
          );
          await Spdb.setEmployeeLogin(
            model: employee,
            cid: result["collectionId"],
            logoUrl: result["companyLogo"],
          );
        }

        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
        }
      } catch (e, st) {
        await ErrorService.recordError(e, st);

        FlushBar.show(context, e.toString(), isSuccess: false);
      }
    }
  }

  /// Converts a [LocationCheckResult] into the appropriate user-facing action.
  void _handleLocationResult(LocationCheckResult result) {
    switch (result) {
      case LocationCheckResult.serviceDisabled:
        _showLocationDialog(
          icon: Iconsax.gps_slash,
          iconColor: Colors.orange,
          title: 'Location Services Disabled',
          message:
              'Your GPS is turned off. Please enable Location Services on '
              'your device to log in.',
          primaryLabel: 'Open Settings',
          primaryAction: () {
            Navigator.pop(context);
            LocationService.openLocationSettings();
          },
        );

      case LocationCheckResult.permissionDenied:
        FlushBar.show(
          context,
          'Location permission is required to log in. '
          'Please grant it and try again.',
          isSuccess: false,
        );

      case LocationCheckResult.permissionDeniedForever:
        _showLocationDialog(
          icon: Iconsax.lock,
          iconColor: Colors.red,
          title: 'Location Permission Required',
          message:
              'Location access has been permanently denied. '
              'Open App Settings and grant the Location permission to continue.',
          primaryLabel: 'Open App Settings',
          primaryAction: () {
            Navigator.pop(context);
            LocationService.openAppSettings();
          },
        );

      case LocationCheckResult.outsideRadius:
        _showLocationDialog(
          icon: Iconsax.location_slash,
          iconColor: Colors.red,
          title: 'Outside Company Premises',
          message:
              'You must be within the company building to log in. '
              'Please move closer to the office and try again.',
          primaryLabel: 'Try Again',
          primaryAction: () {
            Navigator.pop(context);
            _submitForm();
          },
        );

      case LocationCheckResult.error:
        FlushBar.show(
          context,
          'Unable to verify your location. '
          'Please check your GPS signal and try again.',
          isSuccess: false,
        );

      case LocationCheckResult.success:
        break; // handled by caller — should not reach here
    }
  }

  /// Generic location-issue dialog with a primary action button and dismiss.
  void _showLocationDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback primaryAction,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            // Primary action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: primaryAction,
                child: Text(
                  primaryLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
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
                        "Login",
                        style: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Don't have account?",
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          TextButton(
                            child: Text(
                              "Register",
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            onPressed: () {
                              Navigate.route(
                                context,
                                const CompanyRegistration(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Employee Id or Email",
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          FormFields(
                            controller: _email,
                            valid: (value) {
                              if (value == null || value.isEmpty) {
                                return "Employee Id or Email is required";
                              }

                              if (value.contains("@")) {
                                return Validation.validEmail(
                                  input: value,
                                  isReq: true,
                                );
                              }

                              return Validation.commonValidation(
                                input: value,
                                isReq: true,
                                label: "Employee Id or Email",
                              );
                            },
                            keyboardType: TextInputType.text,
                            hintText: "Enter Employee Id or Email",
                            prefixIcon: const Icon(Iconsax.user, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Password",
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          FormFields(
                            valid: (value) => Validation.commonValidation(
                              input: value ?? '',
                              isReq: true,
                              label: "Password",
                            ),
                            controller: _password,
                            keyboardType: TextInputType.visiblePassword,
                            hintText: "Enter password",
                            obsecureText: !_passwordVisible,
                            prefixIcon: const Icon(Iconsax.lock, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() {
                                _passwordVisible = !_passwordVisible;
                              }),
                              icon: Icon(
                                _passwordVisible
                                    ? Iconsax.eye
                                    : Iconsax.eye_slash,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigate.route(
                                context,
                                const ForgotPassword(),
                              ),
                              child: Text(
                                "Forgot Password?",
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // ── Location hint (mobile employees only) ─────────────
                      if (kIsMobile)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Iconsax.location,
                                  size: 15,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your location will be verified against the '
                                    'company premises before login.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ──────────────────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0052D4),
                              Color(0xFF4364F7),
                              Color(0xFF6FB1FC),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
