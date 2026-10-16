import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../gen/assets.gen.dart';

class DriverDirectoryHeader extends StatelessWidget {
  const DriverDirectoryHeader({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản trị',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Danh sách tài xế',
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _BackButton(onPressed: onBack),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceStrong,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: 'Quay lại',
          onPressed: onPressed,
          icon: Assets.images.icBack.svg(
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.text,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
