import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/admin_driver.dart';

class AdminDriverListPanel extends StatelessWidget {
  const AdminDriverListPanel({required this.drivers, super.key});

  final List<AdminDriver> drivers;

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Không tìm thấy tài xế phù hợp'),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (var index = 0; index < drivers.length; index++) ...[
            _AdminDriverRow(driver: drivers[index]),
            if (index < drivers.length - 1)
              const Divider(height: 1, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class _AdminDriverRow extends StatelessWidget {
  const _AdminDriverRow({required this.driver});

  final AdminDriver driver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          InitialsAvatar(label: driver.initials, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (driver.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    driver.phone,
                    style: const TextStyle(color: AppColors.textSoft),
                  ),
                ],
                if (driver.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    driver.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSoft),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
