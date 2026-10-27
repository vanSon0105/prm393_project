import 'package:delivery_app/base/widget/app_scaffold.dart';
import 'package:delivery_app/gen/colors.gen.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Uber',
                    style: TextStyle(
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      0,
                      Icons.account_circle_outlined,
                      LocaleKeys.login_customer_txt.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleButton(
                      1,
                      Icons.local_shipping_outlined,
                      LocaleKeys.login_driver_txt.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleButton(
                      2,
                      Icons.settings_outlined,
                      LocaleKeys.login_admin_txt.tr(),
                    ),
                  ),
                ],
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
                hintText: '090 123 4567',
                icon: Icons.account_circle_outlined,
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
                hintText: '********',
                icon: Icons.lock_person_outlined,
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    AppNavigate.instance.gotoMap();
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
                  onTap: () {
                    AppNavigate.instance.gotoRegister();
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

  Widget _buildRoleButton(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: false ? Border.all(color: Colors.black12, width: 1) : null,
          boxShadow: false
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: false ? const Color(0xFF2F76DB) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: false ? FontWeight.bold : FontWeight.normal,
                color: false ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
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
