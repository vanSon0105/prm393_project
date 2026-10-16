import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../driver/presentation/providers/driver_provider.dart';

class AdminMetricsStrip extends StatelessWidget {
  const AdminMetricsStrip({required this.metrics, super.key});

  final DriverMetrics metrics;

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
                    value: metrics.totalDrivers.toString().padLeft(2, '0'),
                    label: 'Tài xế',
                    isSmall: isSmall,
                  ),
                ),

                _MetricDivider(height: isSmall ? 52 : 64),

                Expanded(
                  child: _MetricItem(
                    value: metrics.activeDrivers.toString().padLeft(2, '0'),
                    label: 'Đang chạy',
                    isSmall: isSmall,
                  ),
                ),

                _MetricDivider(height: isSmall ? 52 : 64),

                Expanded(
                  child: _MetricItem(
                    value: metrics.pendingRequests.toString().padLeft(2, '0'),
                    label: 'Chờ duyệt',
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
