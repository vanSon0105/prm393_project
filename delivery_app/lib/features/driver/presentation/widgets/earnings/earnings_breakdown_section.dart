import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class EarningsBreakdownSection extends StatelessWidget {
  const EarningsBreakdownSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết thu nhập',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            _row(
              Icons.local_taxi_outlined,
              'Thu nhập chuyến xe',
              '1.100.000 ₫',
            ),
            const SizedBox(height: 14),
            _row(Icons.card_giftcard_outlined, 'Thưởng', '200.000 ₫'),
            const SizedBox(height: 14),
            _row(
              Icons.receipt_long_outlined,
              'Phí nền tảng',
              '-50.000 ₫',
              valueColor: AppColors.danger,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _row(
              Icons.account_balance_wallet_outlined,
              'Tổng cộng',
              '1.250.000 ₫',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: AppColors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.text : AppColors.textSoft,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
