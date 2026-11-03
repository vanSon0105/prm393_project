import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../domain/entities/driver.dart';
import 'driver_request_card.dart';

class DriverRequestListSection extends StatelessWidget {
  const DriverRequestListSection({
    required this.requests,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final List<DriverAccountRequest> requests;
  final ValueChanged<DriverAccountRequest> onApprove;
  final ValueChanged<DriverAccountRequest> onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(LocaleKeys.admin_no_pending_requests.tr()),
            ),
          for (final request in requests) ...[
            DriverRequestCard(
              request: request,
              onApprove: () => onApprove(request),
              onReject: () => onReject(request),
            ),
            if (request != requests.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
