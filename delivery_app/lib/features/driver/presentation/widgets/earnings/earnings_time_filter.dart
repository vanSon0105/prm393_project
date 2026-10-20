import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

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
                    child: Text(filter, textAlign: TextAlign.center),
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
                    color: selected ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onCustomRangeTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                const Icon(Icons.date_range_outlined, color: AppColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tùy chọn thời gian',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateRangeText,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
