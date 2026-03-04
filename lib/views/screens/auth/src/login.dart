import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/views/screens/auth/src/company_registration.dart';
import '/constants/constants.dart';
import '/theme/theme.dart';
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
        futureLoading(context);
        String input = _email.text.trim();
        bool isAdminLogin = input.contains("@");
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
        FlushBar.show(context, "Login Successful");

        if (!isAdminLogin) {
          var data = result["userData"];
          var uid = result["uid"];
          EmployeeModel emp = EmployeeModel.fromMap(uid, data);
          if (emp.isInitialPasswordChanged == false) {
            Navigate.routeReplace(
              context,
              ChangeInitialPassword(
                companyId: result["collectionId"],
                employee: emp,
              ),
            );
            return;
          }
          if (emp.receiveEmailNotifications) {
            LoginAlertModel alertInfo =
                await LoginAlertDeviceInfo.getLoginAlertInfo();
            await EmailService.sendEmail(
              to: [emp.email.trim()],
              toName: [emp.name],
              subject: "New login alert",
              message: EmailTemplates.loginAlert
                  .replaceAll("{ip_address}", alertInfo.ipAddress)
                  .replaceAll("{location}", alertInfo.location)
                  .replaceAll("{datetime}", alertInfo.dateTime.listingDateTime)
                  .replaceAll("{device}", alertInfo.device),
            );
          }
          await Spdb.setEmployeeLogin(model: emp, cid: result["collectionId"]);
          RoleModel role = await RoleService.getRole(uid: emp.role);
          await PermissionService.savePermissions(role.permissions);
          await CacheService.syncAllCollections();
          Navigate.routeReplace(context, MainScreen(isAdmin: false));
          return;
        }

        var data = result["adminData"];
        var uid = result["uid"];
        AdminModel admin = AdminModel.fromMap(uid, data);
        print(
          'the login admins id ${result["collectionId"]}, ${result["uid"]}',
        );

        await Spdb.setAdminLogin(model: admin, cid: result["collectionId"]);
        await PermissionService.savePermissions(AppStrings.permissionsTrueMap);

        await AuthService.saveLoginLogs(
          log: LoginLogsModel(
            loginAlert: (await LoginAlertDeviceInfo.getLoginAlertInfo()),
            user: await Spdb.getUser(),
          ),
        );
        Navigate.routeReplace(context, MainScreen(isAdmin: true));
      } catch (e, st) {
        // if (Navigator.canPop(context)) {
        //   Navigator.pop(context);
        // }
        await ErrorService.recordError(e, st);
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
                              color: const Color(0xFF1C1F23),
                            ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Don't have account?",
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.grey700,
                                ),
                          ),
                          TextButton(
                            child: Text(
                              "Register",
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(
                                    color: const Color(0xFF1565C0),
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
                                  color: AppColors.grey700,
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
                                  color: AppColors.grey700,
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
                                color: AppColors.grey600,
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
                                      color: const Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
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
