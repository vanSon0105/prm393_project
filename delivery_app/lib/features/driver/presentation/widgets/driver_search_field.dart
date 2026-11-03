import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../gen/assets.gen.dart';

class DriverSearchField extends StatelessWidget {
  const DriverSearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: LocaleKeys.admin_search_driver_hint.tr(),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: Assets.images.icMoto.svg(
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(
                AppColors.textSoft,
                BlendMode.srcIn,
              ),
              excludeFromSemantics: true,
            ),
          ),
          hintStyle: const TextStyle(
            color: AppColors.textFaint,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
