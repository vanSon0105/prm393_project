import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../driver/presentation/screens/driver_requests_page.dart';
import '../../../driver/presentation/providers/driver_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_navigation_provider.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import 'admin_dashboard_page.dart';
import 'user_management_page.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(adminNavigationProvider);
    final navigation = ref.read(adminNavigationProvider.notifier);
    void selectTab(int index) {
      if (index == 0) {
        ref.invalidate(adminDashboardOverviewProvider);
        ref.invalidate(adminDriverRequestsProvider);
      } else if (index == 1) {
        ref.invalidate(adminDriverRequestsProvider);
      } else if (index == 2) {
        ref.invalidate(adminUsersListProvider);
      }
      navigation.select(index);
    }

    void showDrivers() {
      ref.read(adminUsersProvider.notifier).selectRole('DRIVER');
      selectTab(2);
    }

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: selectedIndex,
            children: [
              AdminDashboardPage(
                onViewDrivers: showDrivers,
                onViewRequests: () => selectTab(1),
              ),
              if (selectedIndex == 1)
                const DriverRequestsPage()
              else
                const SizedBox.shrink(),
              const UserManagementPage(),
            ],
          ),
        ),
        bottomNavigationBar: AdminBottomNav(
          selectedIndex: selectedIndex,
          onSelected: (index) {
            if (index == 2) {
              ref.read(adminUsersProvider.notifier).selectRole('ALL');
            }
            selectTab(index);
          },
        ),
      ),
    );
  }
}
