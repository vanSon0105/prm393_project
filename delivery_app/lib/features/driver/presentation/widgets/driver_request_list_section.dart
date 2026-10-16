import 'package:flutter/material.dart';

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
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Không có yêu cầu đang chờ duyệt'),
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
