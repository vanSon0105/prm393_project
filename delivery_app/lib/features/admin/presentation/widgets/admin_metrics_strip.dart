import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_dashboard_repository.dart';

class AdminMetricsStrip extends StatelessWidget {
  const AdminMetricsStrip({required this.overview, super.key});

  final AdminDashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 400;
        final isTablet = constraints.maxWidth >= 600;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceStrong,
            border: Border(
              top: BorderSide(color: AppColors.line),
              bottom: BorderSide(color: AppColors.line),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall
                  ? 8
                  : isTablet
                  ? 32
                  : 16,
              vertical: isSmall ? 20 : 28,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    value: overview.totalDrivers.toString().padLeft(2, '0'),
                    label: LocaleKeys.users_role_driver.tr(),
                    isSmall: isSmall,
                  ),
                ),

                _MetricDivider(height: isSmall ? 52 : 64),

                Expanded(
                  child: _MetricItem(
                    value: overview.approvedDrivers.toString().padLeft(2, '0'),
                    label: LocaleKeys.admin_metric_approved.tr(),
                    isSmall: isSmall,
                  ),
                ),

                _MetricDivider(height: isSmall ? 52 : 64),

                Expanded(
                  child: _MetricItem(
                    value: overview.pendingRequests.toString().padLeft(2, '0'),
                    label: LocaleKeys.admin_metric_pending.tr(),
                    isSmall: isSmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: height, color: AppColors.line);
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.value,
    required this.label,
    required this.isSmall,
  });

  final String value;
  final String label;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontSize: isSmall ? 28 : 36,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: isSmall ? 13 : 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
