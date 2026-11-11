import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../driver/presentation/providers/driver_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/admin_metrics_strip.dart';
import '../widgets/admin_finance_shortcuts.dart';
import '../widgets/admin_overview_header.dart';
import '../widgets/admin_request_preview_section.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_top_rated_panel.dart';

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
    final overview = ref.watch(adminDashboardOverviewProvider);
    final requests = ref.watch(adminDriverRequestsProvider);

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

            overview.when(
              data: (data) => AdminMetricsStrip(overview: data),
              loading: () => const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _LoadError(
                message: LocaleKeys.admin_driver_load_error.tr(),
                onRetry: () => ref.invalidate(adminDashboardOverviewProvider),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                0,
              ),
              child: const AdminFinanceShortcuts(),
            ),

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
                        title: LocaleKeys.admin_high_rated_drivers.tr(),
                        actionLabel: LocaleKeys.admin_view_all.tr(),
                        onActionPressed: onViewDrivers,
                      ),

                      SizedBox(height: isMobile ? 14 : 18),

                      overview.when(
                        data: (data) =>
                            AdminTopRatedPanel(drivers: data.topRatedDrivers),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => _LoadError(
                          message: LocaleKeys.admin_driver_load_error.tr(),
                          onRetry: () =>
                              ref.invalidate(adminDashboardOverviewProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: sectionSpacing),

            requests.when(
              data: (items) => AdminRequestPreviewSection(
                requests: items.take(3).toList(growable: false),
                onViewAllPressed: onViewRequests,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _LoadError(
                message: LocaleKeys.admin_requests_load_error.tr(),
                onRetry: () => ref.invalidate(adminDriverRequestsProvider),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(LocaleKeys.admin_try_again.tr()),
          ),
        ],
      ),
    );
  }
}
