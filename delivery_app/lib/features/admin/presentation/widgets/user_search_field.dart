import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class UserSearchField extends StatelessWidget {
  const UserSearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Tìm tên, email, SĐT...',
        hintStyle: TextStyle(color: AppColors.textFaint),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textFaint),
      ),
    );
  }
}
