import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/register/driver_documents_field.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_provider.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_repository.dart';
import 'package:delivery_app/features/auth/register/driver_license_expiry_field.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverResubmitScreen extends ConsumerStatefulWidget {
  const DriverResubmitScreen({super.key, required this.driverId});

  final int driverId;

  @override
  ConsumerState<DriverResubmitScreen> createState() =>
      _DriverResubmitScreenState();
}

class _DriverResubmitScreenState extends ConsumerState<DriverResubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  final _licenseExpiry = TextEditingController();
  final _replacements = <String, RegisterDocument>{};
  int? _vehicleId;
  bool _filled = false;
  RejectedDriverRequest? _originalRequest;
  final _imageRevision = DateTime.now().microsecondsSinceEpoch.toString();

  static const _documentKeys = {
    DriverDocumentType.cccdFront: 'front_side_of_the_identity_card',
    DriverDocumentType.cccdBack: 'the_back_of_the_identity_card',
    DriverDocumentType.drivingLicenseFront: 'driving_license_front_side',
    DriverDocumentType.drivingLicenseBack: 'driving_license_back_side',
  };

  @override
  void dispose() {
    _phone.dispose();
    _plate.dispose();
    _licenseExpiry.dispose();
    super.dispose();
  }

  void _fill(RejectedDriverRequest request) {
    if (_filled) return;
    _filled = true;
    _originalRequest = request;
    _phone.text = request.phoneNumber;
    _plate.text = request.licensePlate;
    _licenseExpiry.text = request.licensePlateExpiredDate;
    _vehicleId = request.vehicleId;
    setState(() {});
  }

  Future<void> _chooseDocument(String key) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        _notice(LocaleKeys.register_file_size_error.tr());
        return;
      }
      setState(() {
        _replacements[key] = RegisterDocument(name: file.name, bytes: bytes);
      });
    } catch (_) {
      if (mounted) _notice(LocaleKeys.register_file_read_error.tr());
    }
  }

  String _imageUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.pathSegments.isEmpty) return raw;
    return Uri.parse(Environment.baseUrl)
        .resolve('/image/${Uri.encodeComponent(uri.pathSegments.last)}')
        .replace(queryParameters: {'v': _imageRevision})
        .toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _vehicleId == null) return;
    if (_documentKeys.values.any(
      (key) =>
          (_originalRequest?.documentUrls[key] ?? '').isEmpty &&
          !_replacements.containsKey(key),
    )) {
      _notice(LocaleKeys.register_documents_required.tr());
      return;
    }
    try {
      await ref
          .read(driverResubmitActionsProvider.notifier)
          .submit(
            widget.driverId,
            DriverResubmitData(
              phoneNumber: _phone.text,
              vehicleId: _vehicleId!,
              licensePlate: _plate.text,
              licensePlateExpiredDate: _licenseExpiry.text,
              documents: {..._replacements},
            ),
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(LocaleKeys.driver_resubmit_success_title.tr()),
          content: Text(LocaleKeys.driver_resubmit_success_message.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(LocaleKeys.register_go_login.tr()),
            ),
          ],
        ),
      );
      if (mounted) AppNavigate.instance.gotoLogin();
    } catch (_) {
      if (mounted) _notice(LocaleKeys.driver_resubmit_error.tr());
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(rejectedDriverRequestProvider(widget.driverId), (_, next) {
      if (next case AsyncData(value: final request)) _fill(request);
    });
    final request = ref.watch(rejectedDriverRequestProvider(widget.driverId));
    if (!_filled) {
      switch (request) {
        case AsyncData(value: final data):
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_filled) _fill(data);
          });
        default:
          break;
      }
    }
    final vehicles = ref.watch(driverResubmitVehiclesProvider);
    final submitting = ref
        .watch(driverResubmitActionsProvider)
        .contains(widget.driverId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: LocaleKeys.register_go_login.tr(),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNavigate.instance.gotoLogin(),
        ),
        title: Text(LocaleKeys.driver_resubmit_title.tr()),
      ),
      bottomNavigationBar: request is AsyncData && vehicles is AsyncData
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: submitting || !_filled ? null : _submit,
                  child: Text(
                    submitting
                        ? LocaleKeys.register_submitting.tr()
                        : LocaleKeys.driver_resubmit_send.tr(),
                  ),
                ),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: switch ((request, vehicles)) {
            (AsyncError(), _) || (_, AsyncError()) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocaleKeys.driver_resubmit_load_error.tr()),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(
                        rejectedDriverRequestProvider(widget.driverId),
                      );
                      ref.invalidate(driverResubmitVehiclesProvider);
                    },
                    child: Text(LocaleKeys.admin_try_again.tr()),
                  ),
                ],
              ),
            ),
            (AsyncData(value: final data), AsyncData(value: final types)) =>
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      LocaleKeys.driver_resubmit_description.tr(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          LocaleKeys.driver_resubmit_reason.tr(
                            namedArgs: {'reason': data.reason},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.profile_phone.tr(),
                      ),
                      validator: (value) =>
                          RegExp(r'^0\d{9}$')
                              .hasMatch((value ?? '').replaceAll(' ', ''))
                          ? null
                          : LocaleKeys.register_phone_error.tr(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _vehicleId,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.register_vehicle_type.tr(),
                      ),
                      items: [
                        for (final type in types)
                          if (type.id != null)
                            DropdownMenuItem(
                              value: type.id!,
                              child: Text(type.name ?? '#${type.id}'),
                            ),
                      ],
                      onChanged: (id) => setState(() => _vehicleId = id),
                      validator: (id) => id == null
                          ? LocaleKeys.register_vehicle_required.tr()
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _plate,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.register_license_plate.tr(),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? LocaleKeys.register_plate_required.tr()
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DriverLicenseExpiryField(controller: _licenseExpiry),
                    const SizedBox(height: 24),
                    Text(
                      LocaleKeys.register_documents_title.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(LocaleKeys.driver_resubmit_documents_hint.tr()),
                    const SizedBox(height: 8),
                    for (final entry in _documentKeys.entries)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key.label),
                              if (_replacements[entry.value]
                                  case final replacement?)
                                Image.memory(
                                  replacement.bytes,
                                  height: 140,
                                  fit: BoxFit.contain,
                                )
                              else if ((data.documentUrls[entry.value] ?? '')
                                  .isNotEmpty)
                                Image.network(
                                  _imageUrl(data.documentUrls[entry.value]!),
                                  height: 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Text(
                                    LocaleKeys.driver_resubmit_image_error.tr(),
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: submitting
                                    ? null
                                    : () => _chooseDocument(entry.value),
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _replacements[entry.value]?.name ??
                                      LocaleKeys.register_change_file.tr(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}
