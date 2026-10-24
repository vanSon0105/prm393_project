import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../gen/assets.gen.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _AdminNavItem(
                key: ValueKey('admin-nav-overview'),
                icon: Assets.images.icAdmin,
                label: LocaleKeys.nav_overview.tr(),
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _AdminNavItem(
                key: ValueKey('admin-nav-drivers'),
                icon: Assets.images.icDriver,
                label: LocaleKeys.nav_driver.tr(),
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _AdminNavItem(
                key: ValueKey('admin-nav-requests'),
                icon: Assets.images.icDriverRequest,
                label: LocaleKeys.nav_requests.tr(),
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _AdminNavItem(
                key: ValueKey('admin-nav-users'),
                icon: Assets.images.icUsesGroup,
                label: LocaleKeys.nav_users.tr(),
                selected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
    super.key,
  });

  final SvgGenImage icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.textFaint;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                excludeFromSemantics: true,
              ),
              SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
