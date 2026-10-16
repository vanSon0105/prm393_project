import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../driver/presentation/screens/driver_list_page.dart';
import '../../../driver/presentation/screens/driver_requests_page.dart';
import '../providers/admin_navigation_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import 'admin_dashboard_page.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(adminNavigationProvider);
    final navigation = ref.read(adminNavigationProvider.notifier);

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: selectedIndex,
            children: [
              AdminDashboardPage(
                onViewDrivers: () => navigation.select(1),
                onViewRequests: () => navigation.select(2),
              ),
              DriverListPage(onBack: () => navigation.select(0)),
              DriverRequestsPage(onBack: () => navigation.select(0)),
            ],
          ),
        ),
        bottomNavigationBar: AdminBottomNav(
          selectedIndex: selectedIndex,
          onSelected: navigation.select,
        ),
      ),
    );
  }
}
