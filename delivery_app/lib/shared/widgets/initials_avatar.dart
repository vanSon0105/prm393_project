import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.label,
    this.size = 42,
    this.backgroundColor = AppColors.blueSoft,
    this.foregroundColor = AppColors.blue,
    super.key,
  });

  final String label;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: size * 0.29,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
