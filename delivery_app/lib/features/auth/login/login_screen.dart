import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/responsive_auth_layout.dart';

enum UserRole { customer, driver, admin }

extension on UserRole {
  String get label => switch (this) {
    UserRole.customer => LocaleKeys.login_customer_txt.tr(),
    UserRole.driver => LocaleKeys.login_driver_txt.tr(),
    UserRole.admin => LocaleKeys.login_admin_txt.tr(),
  };
  IconData get icon => switch (this) {
    UserRole.customer => Icons.person_outline_rounded,
    UserRole.driver => Icons.two_wheeler_rounded,
    UserRole.admin => Icons.verified_user_outlined,
  };
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocaleKeys.login_success_role.tr(namedArgs: {'role': _role.label}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      brandTitle: LocaleKeys.splash_brand_title.tr(),
      brandSubtitle: LocaleKeys.splash_brand_subtitle.tr(),
      brandChips: [
        BrandChip(
          label: LocaleKeys.splash_chip_food.tr(),
          icon: Icons.two_wheeler_rounded,
        ),
        BrandChip(
          label: LocaleKeys.splash_chip_goods.tr(),
          icon: Icons.inventory_2_outlined,
        ),
        BrandChip(
          label: LocaleKeys.splash_chip_rides.tr(),
          icon: Icons.directions_car_outlined,
        ),
      ],
      form: (size) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(size: size),
            AuthHeading(
              title: LocaleKeys.login_title_welcome.tr(),
              subtitle: LocaleKeys.login_sub_title_role.tr(),
              size: size,
            ),

            // Chọn vai trò
            Row(
              children: [
                for (final r in UserRole.values) ...[
                  Expanded(
                    child: _RoleTile(
                      role: r,
                      selected: r == _role,
                      onTap: () => setState(() => _role = r),
                    ),
                  ),
                  if (r != UserRole.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 22),

            LabeledField(
              label: LocaleKeys.profile_phone.tr(),
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '090 123 4567',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
                validator: Validators.phone,
              ),
            ),
            const SizedBox(height: 16),

            LabeledField(
              label: LocaleKeys.login_password_label.tr(),
              child: TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: LocaleKeys.login_password_hint.tr(),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? LocaleKeys.login_show_password.tr()
                        : LocaleKeys.login_hide_password.tr(),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.password,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                Text(
                  LocaleKeys.login_remember_me.tr(),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    LocaleKeys.login_forgot_password.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _submit,
              child: Text(LocaleKeys.login_btn_login.tr()),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  LocaleKeys.login_no_account_txt.tr(),
                  style: const TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    LocaleKeys.login_btn_register.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            children: [
              Icon(
                role.icon,
                color: selected ? AppColors.primary : AppColors.muted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                role.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primaryDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
