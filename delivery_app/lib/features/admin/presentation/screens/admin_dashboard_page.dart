import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../driver/presentation/providers/driver_provider.dart';
import '../../../driver/presentation/widgets/driver_list_panel.dart';
import '../widgets/admin_metrics_strip.dart';
import '../widgets/admin_overview_header.dart';
import '../widgets/admin_request_preview_section.dart';
import '../widgets/admin_section_header.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({
    required this.onViewDrivers,
    required this.onViewRequests,
    super.key,
  });

  final VoidCallback onViewDrivers;
  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(driverMetricsProvider);
    final topDrivers = ref.watch(topRatedDriversProvider);
    final latestRequests = ref.watch(latestDriverRequestsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1024;

        final horizontalPadding = isMobile
            ? 16.0
            : isTablet
            ? 32.0
            : 64.0;

        final sectionSpacing = isMobile
            ? 32.0
            : isTablet
            ? 42.0
            : 52.0;

        final maxContentWidth = width >= 1200 ? 1200.0 : double.infinity;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const AdminOverviewHeader(),

            AdminMetricsStrip(metrics: metrics),

            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isMobile ? 24 : 34,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      AdminSectionHeader(
                        title: 'Tài xế có đánh giá cao',
                        actionLabel: 'Xem tất cả',
                        onActionPressed: onViewDrivers,
                      ),

                      SizedBox(height: isMobile ? 14 : 18),

                      DriverListPanel(
                        drivers: topDrivers,
                        mode: DriverListPanelMode.rating,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: sectionSpacing),

            AdminRequestPreviewSection(
              requests: latestRequests,
              onViewAllPressed: onViewRequests,
            ),
          ],
        );
      },
    );
  }
}
