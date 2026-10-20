import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/initials_avatar.dart';

class AccountSummaryCard extends StatelessWidget {
  const AccountSummaryCard({required this.onEditTap, super.key});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const InitialsAvatar(label: 'TA', size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trần Anh',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tài khoản tài xế',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEditTap,
              tooltip: 'Chỉnh sửa hồ sơ',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.blueSoft,
                foregroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
