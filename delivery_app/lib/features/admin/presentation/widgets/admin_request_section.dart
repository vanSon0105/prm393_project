import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/section_heading.dart';
import '../../../driver/domain/entities/driver.dart';
import '../../../driver/presentation/widgets/driver_request_card.dart';

class AdminRequestSection extends StatelessWidget {
  const AdminRequestSection({
    required this.requests,
    this.showActions = false,
    this.onApprove,
    this.onReject,
    super.key,
  });

  final List<DriverAccountRequest> requests;
  final bool showActions;
  final ValueChanged<DriverAccountRequest>? onApprove;
  final ValueChanged<DriverAccountRequest>? onReject;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.blueSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: LocaleKeys.admin_requests_heading.tr(),
              trailing: LocaleKeys.admin_request_count.tr(
                namedArgs: {'count': '${requests.length}'},
              ),
            ),
            const SizedBox(height: 10),
            for (final request in requests) ...[
              DriverRequestCard(
                request: request,
                showActions: showActions,
                onApprove: () => onApprove?.call(request),
                onReject: () => onReject?.call(request),
              ),
              if (request != requests.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
