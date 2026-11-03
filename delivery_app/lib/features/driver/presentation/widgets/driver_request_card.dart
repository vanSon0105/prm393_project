import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/driver.dart';

class DriverRequestCard extends StatelessWidget {
  const DriverRequestCard({
    required this.request,
    this.onApprove,
    this.onReject,
    this.showActions = true,
    super.key,
  });

  final DriverAccountRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(
                  label: request.initials,
                  size: 42,
                  backgroundColor: request.id == 'request-01'
                      ? AppColors.blueSoft
                      : AppColors.surfaceMuted,
                  foregroundColor: request.id == 'request-01'
                      ? AppColors.blue
                      : const Color(0xFF455568),
                ),
                const SizedBox(width: 12),
                Expanded(child: _RequestDescription(request: request)),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        onPressed: onReject,
                        child: Text(LocaleKeys.admin_reject.tr()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        onPressed: onApprove,
                        child: Text(LocaleKeys.admin_approve.tr()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestDescription extends StatelessWidget {
  const _RequestDescription({required this.request});

  final DriverAccountRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _subtitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String _subtitle() {
    final date = request.submittedAt;
    final submittedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final vehicle = switch (request.vehicleType) {
      'Xe máy' => LocaleKeys.admin_vehicle_motorcycle.tr(),
      'Ô tô' => LocaleKeys.admin_vehicle_car.tr(),
      _ => request.vehicleType,
    };
    return LocaleKeys.admin_request_subtitle.tr(
      namedArgs: {'vehicle': vehicle, 'date': submittedDate},
    );
  }
}
