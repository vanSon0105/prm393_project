import 'package:flutter/material.dart';

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
      decoration: const BoxDecoration(
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
                key: const ValueKey('admin-nav-overview'),
                icon: Assets.images.icAdmin,
                label: 'Tổng quan',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _AdminNavItem(
                key: const ValueKey('admin-nav-drivers'),
                icon: Assets.images.icDriver,
                label: 'Tài xế',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _AdminNavItem(
                key: const ValueKey('admin-nav-requests'),
                icon: Assets.images.icDriverRequest,
                label: 'Yêu cầu',
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
              _AdminNavItem(
                key: const ValueKey('admin-nav-users'),
                materialIcon: Icons.manage_accounts_outlined,
                label: 'Người dùng',
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
    this.icon,
    this.materialIcon,
    super.key,
  }) : assert(icon != null || materialIcon != null);

  final SvgGenImage? icon;
  final IconData? materialIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.textFaint;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                icon!.svg(
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  excludeFromSemantics: true,
                )
              else
                Icon(materialIcon, size: 24, color: color),
              const SizedBox(height: 3),
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
