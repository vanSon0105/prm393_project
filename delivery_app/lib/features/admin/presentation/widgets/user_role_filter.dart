import 'package:flutter/material.dart';

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
          label: Text(role),
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
