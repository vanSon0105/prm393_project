import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/app_user.dart';

class UserCard extends StatelessWidget {
  const UserCard({required this.user, required this.onTap, super.key});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                InitialsAvatar(label: user.initials, size: 50),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    switch (user.role) {
                      'CUSTOMER' => LocaleKeys.users_role_customer.tr(),
                      'DRIVER' => LocaleKeys.users_role_driver.tr(),
                      'ADMIN' => LocaleKeys.users_role_admin.tr(),
                      _ => user.role,
                    },
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
