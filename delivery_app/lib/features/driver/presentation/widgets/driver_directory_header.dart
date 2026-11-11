import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';

class DriverDirectoryHeader extends StatelessWidget {
  const DriverDirectoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.users_admin.tr(),
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.admin_driver_list_title.tr(),
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
