import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_driver_request.dart';
import '../providers/driver_provider.dart';
import '../widgets/admin_driver_request_card.dart';
import '../widgets/driver_request_header.dart';

class DriverRequestsPage extends ConsumerWidget {
  const DriverRequestsPage({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(adminDriverRequestsProvider);
    final reviewing = ref.watch(adminDriverReviewProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverRequestHeader(onBack: onBack),
        const SizedBox(height: 54),
        requests.when(
          skipLoadingOnRefresh: false,
          data: (items) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${items.length} yêu cầu chờ duyệt')),
                    IconButton(
                      tooltip: 'Tải lại',
                      onPressed: () =>
                          ref.invalidate(adminDriverRequestsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Không có yêu cầu đang chờ duyệt'),
                  ),
                for (final request in items) ...[
                  AdminDriverRequestCard(
                    request: request,
                    busy: reviewing.contains(request.id),
                    onApprove: () => _approve(context, ref, request),
                    onReject: () => _reject(context, ref, request),
                    onViewDocuments: () => _showDocuments(context, request),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Text(
                  'Không tải được yêu cầu tài xế. Kiểm tra kết nối API rồi thử lại.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(adminDriverRequestsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    AdminDriverRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duyệt tài xế?'),
        content: Text('Cho phép ${request.name} hoạt động trên hệ thống.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _review(context, ref, request, approved: true);
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    AdminDriverRequest request,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectReasonDialog(name: request.name),
    );
    if (reason == null || !context.mounted) return;
    await _review(context, ref, request, approved: false, reason: reason);
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    AdminDriverRequest request, {
    required bool approved,
    String reason = '',
  }) async {
    try {
      await ref
          .read(adminDriverReviewProvider.notifier)
          .review(driverId: request.id, approved: approved, reason: reason);
      if (!context.mounted) return;
      _showResult(
        context,
        approved ? 'Đã duyệt ${request.name}' : 'Đã từ chối ${request.name}',
      );
    } catch (_) {
      if (context.mounted) {
        _showResult(context, 'Không xử lý được yêu cầu. Vui lòng thử lại.');
      }
    }
  }

  void _showDocuments(BuildContext context, AdminDriverRequest request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminDriverDocumentsSheet(request: request),
    );
  }

  void _showResult(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.name});

  final String name;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Từ chối ${widget.name}?'),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Lý do từ chối',
          hintText: 'Nhập lý do để tài xế biết cần bổ sung gì',
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}
