import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../gen/assets.gen.dart';
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
            padding: EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              AppScreenHeader(
                eyebrow: LocaleKeys.settings_account.tr(),
                title: LocaleKeys.settings_title.tr(),
                actionIcon: Icons.close_rounded,
                onActionPressed: () => Navigator.maybePop(context),
              ),
              SizedBox(height: 28),
              AccountSummaryCard(
                onEditTap: () => _showMessage(
                  context,
                  LocaleKeys.settings_edit_profile_demo.tr(),
                ),
              ),
              SizedBox(height: 24),
              SettingSection(
                title: LocaleKeys.settings_customization.tr(),
                children: [
                  SettingOptionTile(
                    icon: Assets.images.icLanguage,
                    title: LocaleKeys.settings_language.tr(),
                    subtitle: LocaleKeys.settings_display_language.tr(),
                    trailing: _buildDropdown(
                      value: context.locale.toLanguageTag(),
                      options: {
                        'en-US': LocaleKeys.settings_english.tr(),
                        'ko-KR': LocaleKeys.settings_korean.tr(),
                      },
                      onSelected: (value) async {
                        notifier.selectLanguage(value);
                        await context.setLocale(
                          value == 'ko-KR'
                              ? const Locale('ko', 'KR')
                              : const Locale('en', 'US'),
                        );
                      },
                    ),
                  ),
                  SettingOptionTile(
                    icon: Assets.images.icMapType,
                    title: LocaleKeys.settings_map_type.tr(),
                    subtitle: LocaleKeys.settings_route_style.tr(),
                    trailing: _buildDropdown(
                      value: setting.selectedMapType,
                      options: {
                        'default': LocaleKeys.settings_map_default.tr(),
                        'satellite': LocaleKeys.settings_map_satellite.tr(),
                      },
                      onSelected: notifier.selectMapType,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              SettingSection(
                title: LocaleKeys.settings_account_app.tr(),
                children: [
                  SettingOptionTile(
                    icon: Assets.images.icUserEdit,
                    title: LocaleKeys.settings_update_info.tr(),
                    subtitle: LocaleKeys.settings_profile_address.tr(),
                    onTap: () => _showMessage(
                      context,
                      LocaleKeys.settings_update_demo.tr(),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSoft,
                    ),
                  ),
                  SettingOptionTile(
                    icon: Assets.images.icInfo,
                    title: LocaleKeys.settings_app_version.tr(),
                    subtitle: LocaleKeys.settings_current_demo.tr(),
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
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dangerSoft,
                    foregroundColor: AppColors.danger,
                  ),
                  icon: Assets.images.icLogout.svg(width: 20, height: 20),
                  label: Text(LocaleKeys.settings_logout.tr()),
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
    required Map<String, String> options,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => options.entries
          .map(
            (option) => PopupMenuItem<String>(
              value: option.key,
              child: Text(option.value),
            ),
          )
          .toList(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              options[value] ?? value,
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(
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
        title: Text(LocaleKeys.settings_logout.tr()),
        content: Text(LocaleKeys.settings_logout_confirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.settings_cancel.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              AppNavigate.instance.gotoLogin();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(LocaleKeys.settings_logout.tr()),
          ),
        ],
      ),
    );
  }
}
