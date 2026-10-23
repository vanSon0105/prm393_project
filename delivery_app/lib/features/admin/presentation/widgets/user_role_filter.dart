import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';

class UserRoleFilter extends StatelessWidget {
  const UserRoleFilter({
    required this.selectedRole,
    required this.onRoleChanged,
    super.key,
  });

  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  static const roles = ['Tất cả', 'Khách hàng', 'Tài xế', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final selected = role == selectedRole;
        return ChoiceChip(
          label: Text(
            switch (role) {
              'Tất cả' => LocaleKeys.users_role_all.tr(),
              'Khách hàng' => LocaleKeys.users_role_customer.tr(),
              'Tài xế' => LocaleKeys.users_role_driver.tr(),
              _ => LocaleKeys.users_role_admin.tr(),
            },
          ),
          selected: selected,
          onSelected: (_) => onRoleChanged(role),
          showCheckmark: false,
          selectedColor: AppColors.blue,
          backgroundColor: AppColors.surfaceStrong,
          side: BorderSide(color: selected ? AppColors.blue : AppColors.line),
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}
