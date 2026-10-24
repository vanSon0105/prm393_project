import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../gen/assets.gen.dart';

class EarningsSummaryCard extends StatelessWidget {
  const EarningsSummaryCard({
    required this.earnings,
    required this.dateRangeText,
    super.key,
  });

  final String earnings;
  final String dateRangeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        border: Border.all(color: AppColors.bluePale),
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.earnings_total_income.tr(),
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  earnings,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 7),
                Text(
                  dateRangeText,
                  style: TextStyle(color: AppColors.textSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Assets.images.icWallet.svg(
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(
                AppColors.blue,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
