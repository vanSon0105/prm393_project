import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/admin/data/admin_dashboard_repository.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/shared/widgets/initials_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AdminTopRatedPanel extends StatelessWidget {
  const AdminTopRatedPanel({required this.drivers, super.key});

  final List<AdminRatedDriver> drivers;

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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(LocaleKeys.admin_no_rated_drivers.tr()),
              ),
            for (var index = 0; index < drivers.length; index++) ...[
              _RatedDriverRow(driver: drivers[index]),
              if (index < drivers.length - 1)
                const Divider(height: 1, color: AppColors.line),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatedDriverRow extends StatelessWidget {
  const _RatedDriverRow({required this.driver});

  final AdminRatedDriver driver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          InitialsAvatar(label: driver.initials, size: 58),
          const SizedBox(width: 18),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.admin_driver_trips_completed.tr(
                    namedArgs: {'count': '${driver.completedTrips}'},
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            driver.rating.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
