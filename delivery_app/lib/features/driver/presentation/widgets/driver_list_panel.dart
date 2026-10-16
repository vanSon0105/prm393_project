import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/driver.dart';
import 'driver_status_chip.dart';

enum DriverListPanelMode { rating, directory }

class DriverListPanel extends StatelessWidget {
  const DriverListPanel({required this.drivers, required this.mode, super.key});

  final List<Driver> drivers;
  final DriverListPanelMode mode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (drivers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Không tìm thấy tài xế phù hợp'),
              ),
            for (var index = 0; index < drivers.length; index++) ...[
              DriverListRow(driver: drivers[index], mode: mode),
              if (index != drivers.length - 1)
                const Divider(height: 1, color: AppColors.line),
            ],
          ],
        ),
      ),
    );
  }
}

class DriverListRow extends StatelessWidget {
  const DriverListRow({required this.driver, required this.mode, super.key});

  final Driver driver;
  final DriverListPanelMode mode;

  @override
  Widget build(BuildContext context) {
    final isRating = mode == DriverListPanelMode.rating;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          InitialsAvatar(
            label: driver.initials,
            size: 58,
            backgroundColor: _avatarBackground,
            foregroundColor: _avatarForeground,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _DriverDescription(
              title: driver.name,
              subtitle: isRating
                  ? '${driver.totalTrips} chuyến đã hoàn thành'
                  : driver.plateNumber,
            ),
          ),
          const SizedBox(width: 12),
          isRating
              ? _DriverRating(value: driver.rating)
              : DriverStatusChip(status: driver.status),
        ],
      ),
    );
  }

  Color get _avatarBackground {
    return switch (driver.id) {
      'driver-01' || 'driver-04' => AppColors.blueSoft,
      'driver-03' || 'driver-06' => const Color(0xFFDCE1E8),
      _ => AppColors.surfaceMuted,
    };
  }

  Color get _avatarForeground {
    return switch (driver.id) {
      'driver-01' || 'driver-04' => AppColors.blue,
      _ => const Color(0xFF31465F),
    };
  }
}

class _DriverDescription extends StatelessWidget {
  const _DriverDescription({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSoft,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DriverRating extends StatelessWidget {
  const _DriverRating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value.toStringAsFixed(2),
      style: const TextStyle(
        color: AppColors.blue,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}
