import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_screen_header.dart';
import 'setting_provider.dart';
import 'widgets/account_summary_card.dart';
import 'widgets/setting_option_tile.dart';
import 'widgets/setting_section.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(settingUiProvider);
    final notifier = ref.read(settingUiProvider.notifier);

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              AppScreenHeader(
                eyebrow: 'Tài khoản',
                title: 'Cài đặt',
                actionIcon: Icons.close_rounded,
                onActionPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 28),
              AccountSummaryCard(
                onEditTap: () =>
                    _showMessage(context, 'Chỉnh sửa hồ sơ (demo)'),
              ),
              const SizedBox(height: 24),
              SettingSection(
                title: 'Tùy chỉnh',
                children: [
                  SettingOptionTile(
                    icon: Icons.translate_outlined,
                    title: 'Ngôn ngữ',
                    subtitle: 'Ngôn ngữ hiển thị',
                    trailing: _buildDropdown(
                      value: setting.selectedLanguage,
                      options: const ['Tiếng Việt', 'English'],
                      onSelected: notifier.selectLanguage,
                    ),
                  ),
                  SettingOptionTile(
                    icon: Icons.layers_outlined,
                    title: 'Loại bản đồ',
                    subtitle: 'Kiểu hiển thị đường đi',
                    trailing: _buildDropdown(
                      value: setting.selectedMapType,
                      options: const ['Mặc định', 'Vệ tinh'],
                      onSelected: notifier.selectMapType,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingSection(
                title: 'Tài khoản và ứng dụng',
                children: [
                  SettingOptionTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Cập nhật thông tin',
                    subtitle: 'Hồ sơ và địa chỉ',
                    onTap: () =>
                        _showMessage(context, 'Cập nhật thông tin (demo)'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSoft,
                    ),
                  ),
                  const SettingOptionTile(
                    icon: Icons.info_outline,
                    title: 'Phiên bản ứng dụng',
                    subtitle: 'Bản demo hiện tại',
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFBEAEC),
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => options
          .map(
            (option) =>
                PopupMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.blue,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
