import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../gen/assets.gen.dart';

class EarningsTimeFilter extends StatelessWidget {
  const EarningsTimeFilter({
    required this.selectedFilter,
    required this.dateRangeText,
    required this.onFilterChanged,
    required this.onCustomRangeTap,
    super.key,
  });

  final String selectedFilter;
  final String dateRangeText;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onCustomRangeTap;

  static const filters = ['Hôm nay', '7 ngày', '30 ngày'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: filters.map((filter) {
            final selected = filter == selectedFilter;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: filter == filters.last ? 0 : 8),
                child: ChoiceChip(
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(
                      switch (filter) {
                        'Hôm nay' => LocaleKeys.earnings_today.tr(),
                        '7 ngày' => LocaleKeys.earnings_seven_days.tr(),
                        _ => LocaleKeys.earnings_thirty_days.tr(),
                      },
                      textAlign: TextAlign.center,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => onFilterChanged(filter),
                  showCheckmark: false,
                  selectedColor: AppColors.blue,
                  backgroundColor: AppColors.surfaceStrong,
                  side: BorderSide(
                    color: selected ? AppColors.blue : AppColors.line,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: onCustomRangeTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selectedFilter == 'Tùy chọn'
                  ? AppColors.blueSoft
                  : AppColors.surfaceStrong,
              border: Border.all(
                color: selectedFilter == 'Tùy chọn'
                    ? AppColors.blue
                    : AppColors.line,
              ),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                Assets.images.icCalendar.svg(
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.blue,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.earnings_custom_time.tr(),
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        dateRangeText,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
