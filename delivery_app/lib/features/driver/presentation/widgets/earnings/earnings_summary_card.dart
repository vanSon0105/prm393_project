import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

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
      padding: const EdgeInsets.all(20),
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
                const Text(
                  'Tổng thu nhập',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  earnings,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.blue,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
