import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_provider.dart';
import '../widgets/driver_request_header.dart';
import '../widgets/driver_request_list_section.dart';

class DriverRequestsPage extends ConsumerWidget {
  const DriverRequestsPage({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(driverRequestsProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverRequestHeader(onBack: onBack),
        const SizedBox(height: 54),
        DriverRequestListSection(
          requests: requests,
          onApprove: (request) {
            ref.read(driverRequestsProvider.notifier).approve(request.id);
            _showResult(context, 'Đã duyệt ${request.name}');
          },
          onReject: (request) {
            ref.read(driverRequestsProvider.notifier).reject(request.id);
            _showResult(context, 'Đã từ chối ${request.name}');
          },
        ),
      ],
    );
  }

  void _showResult(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
