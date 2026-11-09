import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/profile/profile_provider.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../gen/assets.gen.dart';
import '../../../shared/widgets/initials_avatar.dart';

class AccountSummaryCard extends ConsumerWidget {
  const AccountSummaryCard({required this.onEditTap, super.key});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appViewModelProvider);
    final id = app.profileId;
    final profile = id == null || id <= 0
        ? null
        : ref.watch(userProfileProvider(id)).value;
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : LocaleKeys.profile_user.tr();
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final role = switch (app.role) {
      Role.admin => LocaleKeys.users_role_admin.tr(),
      Role.driver => LocaleKeys.profile_driver.tr(),
      Role.customer => LocaleKeys.profile_customer.tr(),
      null => '',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            InitialsAvatar(label: initials, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEditTap,
              tooltip: LocaleKeys.settings_edit_profile.tr(),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.blueSoft,
                foregroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
              icon: Assets.images.icUserEdit.svg(
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.blue,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
