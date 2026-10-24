import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../../core/theme/app_theme.dart';

class EarningsChart extends StatelessWidget {
  const EarningsChart({required this.data, super.key});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.earnings_daily.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 4),
            Text(
              LocaleKeys.earnings_unit.tr(),
              style: TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 174,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.entries.map((entry) {
                  final barHeight = entry.value / maxValue * 118;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value ~/ 1000}k',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 7),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
