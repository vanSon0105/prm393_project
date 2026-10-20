import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class EarningsStatisticsCard extends StatelessWidget {
  const EarningsStatisticsCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.blue, size: 21),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
