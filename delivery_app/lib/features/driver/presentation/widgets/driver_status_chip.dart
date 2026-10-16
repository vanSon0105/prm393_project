import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/driver.dart';

class DriverStatusChip extends StatelessWidget {
  const DriverStatusChip({required this.status, super.key});

  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Text(
      style.label,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: style.foregroundColor,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }

  _DriverStatusStyle _statusStyle(DriverStatus status) {
    return switch (status) {
      DriverStatus.available => const _DriverStatusStyle(
        label: 'Sẵn sàng',
        foregroundColor: AppColors.blue,
      ),
      DriverStatus.delivering => const _DriverStatusStyle(
        label: 'Đang giao',
        foregroundColor: AppColors.textFaint,
      ),
      DriverStatus.offline => const _DriverStatusStyle(
        label: 'Tạm nghỉ',
        foregroundColor: AppColors.textFaint,
      ),
    };
  }
}

class _DriverStatusStyle {
  const _DriverStatusStyle({
    required this.label,
    required this.foregroundColor,
  });

  final String label;
  final Color foregroundColor;
}
