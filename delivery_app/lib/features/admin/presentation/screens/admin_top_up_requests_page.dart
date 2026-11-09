import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/admin/domain/entities/admin_finance.dart';
import 'package:delivery_app/features/admin/presentation/admin_finance_error_message.dart';
import 'package:delivery_app/features/admin/presentation/providers/admin_finance_provider.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTopUpRequestsPage extends ConsumerWidget {
  const AdminTopUpRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(adminTopUpRequestsProvider);
    final reviewing = ref.watch(adminFinanceActionsProvider);
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.admin_top_up_title.tr()),
          actions: [
            IconButton(
              tooltip: LocaleKeys.admin_refresh.tr(),
              onPressed: () => ref.invalidate(adminTopUpRequestsProvider),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: requests.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(adminFinanceLoadErrorMessage(error)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(adminTopUpRequestsProvider),
                    child: Text(LocaleKeys.admin_try_again.tr()),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? Center(child: Text(LocaleKeys.admin_no_top_up_requests.tr()))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _TopUpCard(
                          request: item,
                          busy: reviewing.contains('request-${item.id}'),
                          onApprove: () => _approve(context, ref, item),
                          onReject: () => _reject(context, ref, item),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    DriverTopUpRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.admin_top_up_approve_title.tr()),
        content: Text(LocaleKeys.admin_top_up_approve_message.tr()),
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
    if (confirmed == true && context.mounted) {
      await _review(context, ref, request.id, approved: true);
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    DriverTopUpRequest request,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectTopUpDialog(),
    );
    if (reason != null && context.mounted) {
      await _review(context, ref, request.id, approved: false, reason: reason);
    }
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    int requestId, {
    required bool approved,
    String reason = '',
  }) async {
    try {
      await ref
          .read(adminFinanceActionsProvider.notifier)
          .review(requestId: requestId, approved: approved, reason: reason);
      if (context.mounted) {
        _notice(
          context,
          approved
              ? LocaleKeys.admin_top_up_approved.tr()
              : LocaleKeys.admin_top_up_rejected.tr(),
        );
      }
    } catch (_) {
      if (context.mounted) {
        _notice(context, LocaleKeys.admin_finance_review_error.tr());
      }
    }
  }

  void _notice(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TopUpCard extends StatelessWidget {
  const _TopUpCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final DriverTopUpRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final date = request.createdAt.toLocal();
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final amount = request.amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.driverName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$amount ₫',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.admin_top_up_driver_id.tr(
                namedArgs: {'id': '${request.driverId}'},
              ),
            ),
            Text(
              LocaleKeys.admin_top_up_submitted.tr(
                namedArgs: {'date': dateText},
              ),
            ),
            const SizedBox(height: 8),
            if (request.rejectReason.isNotEmpty)
              Text(
                LocaleKeys.driver_resubmit_reason.tr(
                  namedArgs: {'reason': request.rejectReason},
                ),
              ),
            const SizedBox(height: 12),
            if (request.proofUrl.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(
                        request.proofUrl,
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            LocaleKeys.users_document_load_error.tr(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(LocaleKeys.admin_view_transfer_proof.tr()),
              )
            else
              Text(LocaleKeys.admin_no_transfer_proof.tr()),
            const SizedBox(height: 16),
            if (request.status != TopUpStatus.pending)
              Text(switch (request.status) {
                TopUpStatus.approved => LocaleKeys.admin_top_up_approved.tr(),
                TopUpStatus.rejected => LocaleKeys.admin_top_up_rejected.tr(),
                TopUpStatus.pending => '',
              })
            else if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: Text(LocaleKeys.admin_reject.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: Text(LocaleKeys.admin_approve.tr()),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RejectTopUpDialog extends StatefulWidget {
  const _RejectTopUpDialog();

  @override
  State<_RejectTopUpDialog> createState() => _RejectTopUpDialogState();
}

class _RejectTopUpDialogState extends State<_RejectTopUpDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.admin_top_up_reject_title.tr()),
    content: TextField(
      controller: _controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: LocaleKeys.admin_reject_reason_label.tr(),
      ),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(LocaleKeys.admin_cancel.tr()),
      ),
      FilledButton(
        onPressed: _controller.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _controller.text.trim()),
        child: Text(LocaleKeys.admin_reject.tr()),
      ),
    ],
  );
}
