import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/gen/assets.gen.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: navigationShell.currentIndex == 1
          ? null
          : BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTabSelected,
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
