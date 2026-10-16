import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.trailing,
    this.onTrailingPressed,
    super.key,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;

    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null)
          onTrailingPressed == null
              ? Text(
                  trailing,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : TextButton(
                  onPressed: onTrailingPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.blue,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  child: Text(trailing),
                ),
      ],
    );
  }
}
