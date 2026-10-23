import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../gen/assets.gen.dart';

class EarningsBreakdownSection extends StatelessWidget {
  const EarningsBreakdownSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.earnings_breakdown.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 18),
            _row(
              Assets.images.icCar,
              LocaleKeys.earnings_trip_income.tr(),
              '1.100.000 ₫',
            ),
            SizedBox(height: 14),
            _row(
              Assets.images.icGift,
              LocaleKeys.earnings_bonus.tr(),
              '200.000 ₫',
            ),
            SizedBox(height: 14),
            _row(
              Assets.images.icReceipt,
              LocaleKeys.earnings_platform_fee.tr(),
              '-50.000 ₫',
              valueColor: AppColors.danger,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _row(
              Assets.images.icWallet,
              LocaleKeys.earnings_total.tr(),
              '1.250.000 ₫',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    SvgGenImage icon,
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: icon.svg(
            width: 19,
            height: 19,
            colorFilter: const ColorFilter.mode(
              AppColors.blue,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.text : AppColors.textSoft,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
