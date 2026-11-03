import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

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
      DriverStatus.available => _DriverStatusStyle(
        label: LocaleKeys.admin_driver_status_available.tr(),
        foregroundColor: AppColors.blue,
      ),
      DriverStatus.delivering => _DriverStatusStyle(
        label: LocaleKeys.admin_driver_status_delivering.tr(),
        foregroundColor: AppColors.textFaint,
      ),
      DriverStatus.offline => _DriverStatusStyle(
        label: LocaleKeys.admin_driver_status_offline.tr(),
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
