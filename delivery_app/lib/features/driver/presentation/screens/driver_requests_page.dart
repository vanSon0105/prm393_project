import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

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
                    Expanded(
                      child: Text(
                        LocaleKeys.admin_pending_request_count.tr(
                          namedArgs: {'count': '${items.length}'},
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.admin_refresh.tr(),
                      onPressed: () =>
                          ref.invalidate(adminDriverRequestsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(LocaleKeys.admin_no_pending_requests.tr()),
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
                Text(LocaleKeys.admin_requests_load_error.tr()),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(adminDriverRequestsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(LocaleKeys.admin_try_again.tr()),
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
        title: Text(LocaleKeys.admin_approve_driver_question.tr()),
        content: Text(
          LocaleKeys.admin_approve_driver_message.tr(
            namedArgs: {'name': request.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(LocaleKeys.admin_cancel.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(LocaleKeys.admin_approve.tr()),
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
        approved
            ? LocaleKeys.admin_approved_notice.tr(
                namedArgs: {'name': request.name},
              )
            : LocaleKeys.admin_rejected_notice.tr(
                namedArgs: {'name': request.name},
              ),
      );
    } catch (_) {
      if (context.mounted) {
        _showResult(context, LocaleKeys.admin_review_error.tr());
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
      title: Text(
        LocaleKeys.admin_reject_driver_question.tr(
          namedArgs: {'name': widget.name},
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: LocaleKeys.admin_reject_reason_label.tr(),
          hintText: LocaleKeys.admin_reject_reason_hint.tr(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.admin_cancel.tr()),
        ),
        FilledButton(
          onPressed: controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, controller.text.trim()),
          child: Text(LocaleKeys.admin_reject.tr()),
        ),
      ],
    );
  }
}
