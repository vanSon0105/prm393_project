import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../driver/domain/entities/driver.dart';
import 'admin_section_header.dart';

class AdminRequestPreviewSection extends StatelessWidget {
  const AdminRequestPreviewSection({
    required this.requests,
    required this.onViewAllPressed,
    super.key,
  });

  final List<DriverAccountRequest> requests;
  final VoidCallback onViewAllPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.blueSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 50),
        child: Column(
          children: [
            AdminSectionHeader(
              title: 'Yêu cầu mới',
              actionLabel: 'Xem tất cả',
              onActionPressed: onViewAllPressed,
            ),
            const SizedBox(height: 18),
            if (requests.isEmpty) const Text('Không có yêu cầu đang chờ duyệt'),
            for (final request in requests) ...[
              _RequestPreviewRow(request: request),
              if (request != requests.last) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestPreviewRow extends StatelessWidget {
  const _RequestPreviewRow({required this.request});

  final DriverAccountRequest request;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Row(
          children: [
            InitialsAvatar(
              label: request.initials,
              size: 58,
              backgroundColor: request.id == 'request-01'
                  ? AppColors.blueSoft
                  : AppColors.surfaceMuted,
              foregroundColor: request.id == 'request-01'
                  ? AppColors.blue
                  : const Color(0xFF31465F),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    request.vehicleType,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Assets.images.icContinue.svg(
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(
                AppColors.textFaint,
                BlendMode.srcIn,
              ),
              excludeFromSemantics: true,
            ),
          ],
        ),
      ),
    );
  }
}
