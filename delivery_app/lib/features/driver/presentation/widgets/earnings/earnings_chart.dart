import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class EarningsChart extends StatelessWidget {
  const EarningsChart({required this.data, super.key});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thu nhập theo ngày',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Đơn vị: nghìn đồng',
              style: TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 174,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.entries.map((entry) {
                  final barHeight = entry.value / maxValue * 118;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value ~/ 1000}k',
                            style: const TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            height: barHeight,
                            decoration: const BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(
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
