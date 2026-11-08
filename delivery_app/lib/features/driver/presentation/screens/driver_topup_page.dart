import 'dart:typed_data';

import 'package:delivery_app/features/driver/data/driver_topup_repository.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_topup_provider.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTopupPage extends ConsumerStatefulWidget {
  const DriverTopupPage({super.key});

  @override
  ConsumerState<DriverTopupPage> createState() => _DriverTopupPageState();
}

class _DriverTopupPageState extends ConsumerState<DriverTopupPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  PlatformFile? _proof;
  Uint8List? _proofBytes;
  int? _editingId;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _chooseProof() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 9 * 1024 * 1024) {
        _notice(LocaleKeys.driver_topup_image_size.tr());
        return;
      }
      setState(() {
        _proof = file;
        _proofBytes = bytes;
      });
    } catch (_) {
      if (mounted) _notice(LocaleKeys.register_file_read_error.tr());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final file = _proof;
    final bytes = _proofBytes;
    if (file == null || bytes == null) {
      _notice(LocaleKeys.driver_topup_proof_required.tr());
      return;
    }
    try {
      if (!mounted) return;
      await ref
          .read(driverTopupActionProvider.notifier)
          .submit(
            amount: int.parse(_amount.text.trim()),
            fileName: file.name,
            imageBytes: bytes,
            requestId: _editingId,
          );
      if (!mounted) return;
      setState(() {
        _editingId = null;
        _proof = null;
        _proofBytes = null;
        _amount.clear();
      });
      _notice(LocaleKeys.driver_topup_sent.tr());
    } catch (_) {
      if (mounted) _notice(LocaleKeys.driver_topup_submit_error.tr());
    }
  }

  void _edit(DriverTopupRequest request) {
    setState(() {
      _editingId = request.id;
      _amount.text = request.amount.toString();
      _proof = null;
      _proofBytes = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _amount.clear();
      _proof = null;
      _proofBytes = null;
    });
  }

  Future<void> _showDetail(int id) async {
    try {
      final request = await ref
          .read(driverTopupRepositoryProvider)
          .getDetail(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(LocaleKeys.driver_topup_detail.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${request.amount} ₫ · ${_status(request.status)}'),
                Text(_date(request.createdAt)),
                if (request.rejectReason.isNotEmpty)
                  Text(
                    LocaleKeys.driver_resubmit_reason.tr(
                      namedArgs: {'reason': request.rejectReason},
                    ),
                  ),
                if (request.proofUrl.isNotEmpty)
                  Image.network(
                    request.proofUrl,
                    height: 240,
                    errorBuilder: (_, _, _) =>
                        Text(LocaleKeys.users_document_load_error.tr()),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.admin_cancel.tr()),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) _notice(LocaleKeys.driver_topup_load_error.tr());
    }
  }

  String _status(String value) => switch (value) {
    'APPROVED' => LocaleKeys.driver_topup_approved.tr(),
    'REJECTED' => LocaleKeys.driver_topup_rejected.tr(),
    _ => LocaleKeys.driver_topup_pending.tr(),
  };

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(driverTopupBankProvider);
    final requests = ref.watch(driverTopupRequestsProvider);
    final sending = ref.watch(driverTopupActionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.driver_topup_title.tr()),
        actions: [
          IconButton(
            tooltip: LocaleKeys.admin_refresh.tr(),
            onPressed: () {
              ref.invalidate(driverTopupBankProvider);
              ref.invalidate(driverTopupRequestsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            LocaleKeys.driver_topup_bank_title.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          bank.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _retry(
              LocaleKeys.driver_topup_load_error.tr(),
              () => ref.invalidate(driverTopupBankProvider),
            ),
            data: (details) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SelectableText(details.number),
                    Text(details.holder),
                    if (details.qrUrl.isNotEmpty)
                      Image.network(
                        details.qrUrl,
                        height: 190,
                        errorBuilder: (_, _, _) =>
                            Text(LocaleKeys.users_document_load_error.tr()),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _editingId == null
                ? LocaleKeys.driver_topup_new.tr()
                : LocaleKeys.driver_topup_edit.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.driver_topup_amount.tr(),
                    suffixText: '₫',
                  ),
                  validator: (value) {
                    final amount = int.tryParse((value ?? '').trim());
                    return amount == null || amount <= 0 || amount > 2147483647
                        ? LocaleKeys.driver_topup_amount_error.tr()
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: sending ? null : _chooseProof,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _proof?.name ?? LocaleKeys.driver_topup_choose_proof.tr(),
                  ),
                ),
                if (_proofBytes case final bytes?) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Image.memory(
                        bytes,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            LocaleKeys.users_document_load_error.tr(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: sending ? null : _submit,
                  child: Text(
                    sending
                        ? LocaleKeys.register_submitting.tr()
                        : LocaleKeys.driver_topup_send.tr(),
                  ),
                ),
                if (_editingId != null)
                  TextButton(
                    onPressed: sending ? null : _cancelEdit,
                    child: Text(LocaleKeys.admin_cancel.tr()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LocaleKeys.driver_topup_history.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          requests.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _retry(
              LocaleKeys.driver_topup_load_error.tr(),
              () => ref.invalidate(driverTopupRequestsProvider),
            ),
            data: (items) => items.isEmpty
                ? Text(LocaleKeys.driver_topup_empty.tr())
                : Column(
                    children: [
                      for (final item in items)
                        Card(
                          child: ListTile(
                            title: Text(
                              '${item.amount} ₫ · ${_status(item.status)}',
                            ),
                            subtitle: Text(_date(item.createdAt)),
                            onTap: () => _showDetail(item.id),
                            trailing: item.status == 'REJECTED'
                                ? TextButton(
                                    onPressed: () => _edit(item),
                                    child: Text(
                                      LocaleKeys.driver_topup_edit.tr(),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _retry(String message, VoidCallback retry) => Column(
    children: [
      Text(message),
      TextButton(
        onPressed: retry,
        child: Text(LocaleKeys.admin_try_again.tr()),
      ),
    ],
  );
}
