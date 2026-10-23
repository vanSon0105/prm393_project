import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../core/theme/app_theme.dart';
import '../../../gen/assets.gen.dart';
import '../../../shared/widgets/initials_avatar.dart';

class AccountSummaryCard extends StatelessWidget {
  const AccountSummaryCard({required this.onEditTap, super.key});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            InitialsAvatar(label: 'TA', size: 54),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trần Anh',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 4),
                  Text(
                    LocaleKeys.settings_driver_account.tr(),
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12),
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
