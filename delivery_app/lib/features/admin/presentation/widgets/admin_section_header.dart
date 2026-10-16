import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionPressed,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: AppColors.blue,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
