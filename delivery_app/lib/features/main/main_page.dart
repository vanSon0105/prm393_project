import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/gen/assets.gen.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  void _onTabSelected(int index, WidgetRef ref) {
    if (index == 2) {
      final app = ref.read(appViewModelProvider);
      if (app.role == Role.driver && app.profileId != null) {
        ref.invalidate(driverWalletBalanceProvider(app.profileId!));
      }
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTabSelected(index, ref),
        items: [
          BottomNavigationBarItem(
            icon: Assets.images.icMap.svg(width: 24, height: 24),
            label: LocaleKeys.trip_home.tr(),
          ),
          BottomNavigationBarItem(
            icon: Assets.images.icRoute.svg(width: 24, height: 24),
            label: LocaleKeys.trip_tab.tr(),
          ),
          BottomNavigationBarItem(
            icon: Assets.images.icSettings.svg(width: 24, height: 24),
            label: LocaleKeys.trip_setting.tr(),
          ),
        ],
      ),
    );
  }
}
