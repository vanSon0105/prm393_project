import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../gen/assets.gen.dart';

class UserSearchField extends StatelessWidget {
  const UserSearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: LocaleKeys.users_search_hint.tr(),
        hintStyle: TextStyle(color: AppColors.textFaint),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Assets.images.icSearch.svg(
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.textFaint,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
