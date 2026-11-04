import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/register/register_view_model.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/responsive_auth_layout.dart';
import 'driver_documents_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final Role role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _documentsKey =
      GlobalKey<FormFieldState<Map<DriverDocumentType, PlatformFile>>>();
  int? _vehicleId;
  bool _obscure = true;

  RegisterViewModel get _viewModel =>
      ref.read(registerViewModelProvider(widget.role).notifier);

  @override
  void initState() {
    super.initState();
    if (widget.role == Role.driver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _viewModel.getVehicleType();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _fullNameCtrl,
      _userNameCtrl,
      _phoneCtrl,
      _plateCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _pair(ScreenSize size, Widget first, Widget second) {
    if (size == ScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 16), second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Future<void> _switchRole(Role role) async {
    if (role == widget.role) return;
    if (role == Role.driver && !await AppNavigate.instance.gotoDriverTerms()) {
      return;
    }
    if (mounted) AppNavigate.instance.gotoRegister(role);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final documents = <String, RegisterDocument>{};
    if (widget.role == Role.driver) {
      final selected = _documentsKey.currentState?.value;
      if (selected == null ||
          selected.length != DriverDocumentType.values.length) {
        return;
      }
      try {
        for (final entry in <String, DriverDocumentType>{
          'front_side_of_the_identity_card': DriverDocumentType.cccdFront,
          'the_back_of_the_identity_card': DriverDocumentType.cccdBack,
          'driving_license_front_side': DriverDocumentType.drivingLicenseFront,
          'driving_license_back_side': DriverDocumentType.drivingLicenseBack,
        }.entries) {
          final file = selected[entry.value]!;
          documents[entry.key] = RegisterDocument(
            name: file.name,
            bytes: await file.readAsBytes(),
          );
        }
      } catch (_) {
        if (mounted) _notice(LocaleKeys.register_file_read_error.tr());
        return;
      }
    }

    if (!mounted) return;
    try {
      await _viewModel.register(
        RegisterAccountRequest(
          fullName: _fullNameCtrl.text,
          userName: _userNameCtrl.text,
          password: _passCtrl.text,
          phoneNumber: _phoneCtrl.text,
          role: widget.role,
          vehicleId: _vehicleId,
          licensePlate: widget.role == Role.driver ? _plateCtrl.text : null,
          documents: documents,
        ),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(LocaleKeys.register_success_title.tr()),
          content: Text(
            widget.role == Role.driver
                ? LocaleKeys.register_driver_pending.tr()
                : LocaleKeys.register_customer_success.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(LocaleKeys.register_go_login.tr()),
            ),
          ],
        ),
      );
      if (mounted) AppNavigate.instance.gotoLogin();
    } on DioException catch (error) {
      if (!mounted) return;
      _notice(
        error.response?.statusCode == 409
            ? LocaleKeys.register_conflict_error.tr()
            : LocaleKeys.register_submit_error.tr(),
      );
    } catch (_) {
      if (mounted) _notice(LocaleKeys.register_submit_error.tr());
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider(widget.role));
    return ResponsiveAuthLayout(
      cardMaxWidth: 560,
      brandTitle: LocaleKeys.register_brand_title.tr(),
      brandSubtitle: LocaleKeys.register_brand_subtitle.tr(),
      brandChips: [
        BrandChip(label: LocaleKeys.register_brand_free.tr()),
        BrandChip(label: LocaleKeys.register_brand_payment.tr()),
      ],
      form: (size) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(
              size: size,
              eyebrow: LocaleKeys.register_create_account.tr(),
            ),
            AuthHeading(
              title: LocaleKeys.register_heading.tr(),
              subtitle: LocaleKeys.register_subtitle.tr(),
              size: size,
            ),
            _Segment(value: widget.role, onChanged: _switchRole),
            const SizedBox(height: 22),
            LabeledField(
              label: LocaleKeys.profile_full_name.tr(),
              child: TextFormField(
                controller: _fullNameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: LocaleKeys.register_full_name_hint.tr(),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) =>
                    (value ?? '').trim().length < 2 ||
                        (value ?? '').trim().length > 45
                    ? LocaleKeys.register_full_name_error.tr()
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: LocaleKeys.login_phone_label.tr(),
              child: TextFormField(
                controller: _userNameCtrl,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: LocaleKeys.register_username_hint.tr(),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    RegExp(r'^[a-zA-Z0-9_.]{3,45}$')
                        .hasMatch(value?.trim() ?? '')
                    ? null
                    : LocaleKeys.register_username_error.tr(),
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: LocaleKeys.profile_phone.tr(),
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: LocaleKeys.register_phone_hint.tr(),
                  prefixIcon: const Icon(Icons.phone_iphone_rounded),
                ),
                validator: (value) =>
                    RegExp(r'^0\d{9}$')
                        .hasMatch((value ?? '').replaceAll(' ', ''))
                    ? null
                    : LocaleKeys.register_phone_error.tr(),
              ),
            ),
            if (state.isDriver) ...[
              const SizedBox(height: 16),
              _pair(
                size,
                LabeledField(
                  label: LocaleKeys.register_vehicle_type.tr(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _vehicleId,
                        isExpanded: true,
                        items: [
                          for (final vehicle in state.vehicles)
                            if (vehicle.id != null)
                              DropdownMenuItem(
                                value: vehicle.id!,
                                child: Text(vehicle.name ?? '#${vehicle.id}'),
                              ),
                        ],
                        onChanged: state.loadingVehicles
                            ? null
                            : (value) => setState(() => _vehicleId = value),
                        decoration: InputDecoration(
                          hintText: state.loadingVehicles
                              ? LocaleKeys.loading_txt.tr()
                              : LocaleKeys.register_select_vehicle.tr(),
                          prefixIcon: const Icon(Icons.two_wheeler_rounded),
                        ),
                        validator: (value) => value == null
                            ? LocaleKeys.register_vehicle_required.tr()
                            : null,
                      ),
                      if (state.vehicleLoadFailed) ...[
                        Text(LocaleKeys.register_vehicle_load_error.tr()),
                        TextButton(
                          onPressed: _viewModel.getVehicleType,
                          child: Text(LocaleKeys.admin_try_again.tr()),
                        ),
                      ],
                    ],
                  ),
                ),
                LabeledField(
                  label: LocaleKeys.register_license_plate.tr(),
                  child: TextFormField(
                    controller: _plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.register_plate_hint.tr(),
                      prefixIcon: const Icon(Icons.credit_card_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? LocaleKeys.register_plate_required.tr()
                        : null,
                  ),
                ),
              ),
              const Divider(height: 32),
              Text(
                LocaleKeys.register_documents_title.tr(),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                LocaleKeys.register_documents_description.tr(),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              DriverDocumentsField(key: _documentsKey),
            ],
            const SizedBox(height: 16),
            _pair(
              size,
              LabeledField(
                label: LocaleKeys.login_password_label.tr(),
                child: TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.register_password_hint.tr(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) => (value ?? '').length < 6
                      ? LocaleKeys.register_password_error.tr()
                      : null,
                ),
              ),
              LabeledField(
                label: LocaleKeys.register_confirm_password.tr(),
                child: TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.register_confirm_hint.tr(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) =>
                      value != _passCtrl.text || (value ?? '').isEmpty
                      ? LocaleKeys.register_password_mismatch.tr()
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (state.isDriver)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleKeys.register_driver_terms_accepted.tr(),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state.submitting || state.loadingVehicles
                  ? null
                  : _submit,
              child: Text(
                state.submitting
                    ? LocaleKeys.register_submitting.tr()
                    : LocaleKeys.register_submit.tr(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(LocaleKeys.register_have_account.tr()),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(LocaleKeys.login_btn_login.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.value, required this.onChanged});

  final Role value;
  final ValueChanged<Role> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2F7),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        for (final role in [Role.customer, Role.driver])
          Expanded(
            child: TextButton(
              onPressed: () => onChanged(role),
              style: TextButton.styleFrom(
                backgroundColor: role == value
                    ? AppColors.surface
                    : Colors.transparent,
                foregroundColor: role == value
                    ? AppColors.ink
                    : AppColors.muted,
              ),
              child: Text(role.title),
            ),
          ),
      ],
    ),
  );
}
