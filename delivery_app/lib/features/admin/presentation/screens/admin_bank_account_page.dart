import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/admin/domain/entities/admin_finance.dart';
import 'package:delivery_app/features/admin/presentation/admin_finance_error_message.dart';
import 'package:delivery_app/features/admin/presentation/providers/admin_finance_provider.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminBankAccountPage extends ConsumerStatefulWidget {
  const AdminBankAccountPage({super.key});

  @override
  ConsumerState<AdminBankAccountPage> createState() =>
      _AdminBankAccountPageState();
}

class _AdminBankAccountPageState extends ConsumerState<AdminBankAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountHolder = TextEditingController();
  final _transferNote = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _bankName.dispose();
    _accountNumber.dispose();
    _accountHolder.dispose();
    _transferNote.dispose();
    super.dispose();
  }

  void _fill(AdminBankAccount? account) {
    if (_loaded) return;
    _loaded = true;
    _bankName.text = account?.bankName ?? '';
    _accountNumber.text = account?.accountNumber ?? '';
    _accountHolder.text = account?.accountHolder ?? '';
    _transferNote.text = account?.transferNote ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final account = AdminBankAccount(
      bankName: _bankName.text,
      accountNumber: _accountNumber.text,
      accountHolder: _accountHolder.text,
      transferNote: _transferNote.text,
    );
    try {
      await ref
          .read(adminFinanceActionsProvider.notifier)
          .updateBankAccount(account);
      if (mounted) _notice(LocaleKeys.admin_bank_saved.tr());
    } catch (_) {
      if (mounted) _notice(LocaleKeys.admin_finance_save_error.tr());
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminBankAccountProvider, (_, next) {
      if (next case AsyncData(value: final account)) _fill(account);
    });
    final account = ref.watch(adminBankAccountProvider);
    final saving = ref.watch(adminFinanceActionsProvider).contains('bank');

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.admin_bank_title.tr())),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  LocaleKeys.admin_bank_description.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (account.isLoading && !_loaded)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (account.hasError) ...[
                    _FeedbackCard(
                      message: adminFinanceLoadErrorMessage(account.error),
                      onRetry: () => ref.invalidate(adminBankAccountProvider),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _bankName,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.admin_bank_name.tr(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? LocaleKeys.admin_field_required.tr()
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountNumber,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.admin_account_number.tr(),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              RegExp(r'^\d{6,30}$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : LocaleKeys.admin_account_number_invalid.tr(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountHolder,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.admin_account_holder.tr(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? LocaleKeys.admin_field_required.tr()
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _transferNote,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.admin_transfer_note.tr(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: saving ? null : _save,
                          child: Text(
                            saving
                                ? LocaleKeys.admin_saving.tr()
                                : LocaleKeys.admin_save_bank.tr(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            child: Text(LocaleKeys.admin_try_again.tr()),
          ),
        ],
      ),
    ),
  );
}
