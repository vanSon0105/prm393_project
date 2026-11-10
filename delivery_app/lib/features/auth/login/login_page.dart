import 'package:delivery_app/base/widget/app_scaffold.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/login/login_view_model.dart';
import 'package:delivery_app/gen/colors.gen.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loginViewModelProvider);
    return AppScaffold(
      showAppbar: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.app_name.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F76DB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                LocaleKeys.login_title_welcome.tr(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.login_sub_title_role.tr(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Text(
                LocaleKeys.login_phone_label.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: LocaleKeys.login_username_hint.tr(),
                icon: Icons.account_circle_outlined,
                controller: userController,
              ),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.login_password_label.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: LocaleKeys.login_password_hint.tr(),
                controller: passController,
                icon: Icons.lock_person_outlined,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? LocaleKeys.login_show_password.tr()
                      : LocaleKeys.login_hide_password.tr(),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(loginViewModelProvider.notifier)
                        .login(
                          userName: userController.text,
                          password: passController.text,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorName.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    LocaleKeys.login_btn_login.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: InkWell(
                  onTap: () async {
                    final role = await showModalBottomSheet<Role>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              LocaleKeys.login_register_as.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.account_circle_outlined,
                              ),
                              title: Text(LocaleKeys.login_customer_txt.tr()),
                              onTap: () =>
                                  Navigator.pop(context, Role.customer),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.local_shipping_outlined,
                              ),
                              title: Text(LocaleKeys.login_driver_txt.tr()),
                              onTap: () => Navigator.pop(context, Role.driver),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (!mounted || role == null) return;
                    if (role == Role.driver &&
                        !await AppNavigate.instance.gotoDriverTerms()) {
                      return;
                    }
                    if (!mounted) return;
                    AppNavigate.instance.gotoRegister(role);
                  },
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: ColorName.black,
                      ),
                      children: [
                        TextSpan(text: LocaleKeys.login_no_account_txt.tr()),
                        TextSpan(
                          text: LocaleKeys.login_btn_register.tr(),
                          style: const TextStyle(
                            color: ColorName.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !obscureText,
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.black45,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2F76DB), width: 1.5),
        ),
      ),
    );
  }
}
