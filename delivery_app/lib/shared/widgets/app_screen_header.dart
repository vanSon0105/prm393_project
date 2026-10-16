import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    required this.eyebrow,
    required this.title,
    this.actionIcon = Icons.settings_outlined,
    this.onActionPressed,
    super.key,
  });

  final String eyebrow;
  final String title;
  final IconData actionIcon;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        _HeaderButton(icon: actionIcon, onPressed: onActionPressed),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceStrong,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.text, size: 21),
        ),
      ),
    );
  }
}
