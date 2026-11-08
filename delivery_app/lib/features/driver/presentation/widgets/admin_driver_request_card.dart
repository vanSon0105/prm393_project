import 'package:delivery_app/config/environment.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/admin_driver_request.dart';

class AdminDriverRequestCard extends StatelessWidget {
  const AdminDriverRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onViewApplication,
    super.key,
  });

  final AdminDriverRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewApplication;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(label: request.initials, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (request.phone.isNotEmpty)
                        Text(
                          request.phone,
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.address.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request.address,
                style: const TextStyle(color: AppColors.textSoft),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onViewApplication,
              icon: const Icon(Icons.description_outlined),
              label: Text(LocaleKeys.admin_view_application.tr()),
            ),
            const SizedBox(height: 8),
            if (busy)
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
                  const SizedBox(width: 10),
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

class AdminDriverApplicationSheet extends StatefulWidget {
  const AdminDriverApplicationSheet({required this.request, super.key});

  final AdminDriverRequest request;

  @override
  State<AdminDriverApplicationSheet> createState() =>
      _AdminDriverApplicationSheetState();
}

class _AdminDriverApplicationSheetState
    extends State<AdminDriverApplicationSheet> {
  final _imageRevision = DateTime.now().microsecondsSinceEpoch.toString();

  String _imageUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.pathSegments.isEmpty) return raw;
    return Uri.parse(Environment.baseUrl)
        .resolve('/image/${Uri.encodeComponent(uri.pathSegments.last)}')
        .replace(queryParameters: {'v': _imageRevision})
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final documents = <(String, String)>[
      (LocaleKeys.users_license_front.tr(), widget.request.licenseFrontUrl),
      (LocaleKeys.users_license_back.tr(), widget.request.licenseBackUrl),
      (LocaleKeys.users_identity_front.tr(), widget.request.identityFrontUrl),
      (LocaleKeys.users_identity_back.tr(), widget.request.identityBackUrl),
    ];

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              LocaleKeys.admin_application_title.tr(
                namedArgs: {'name': widget.request.name},
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow(LocaleKeys.profile_full_name.tr(), widget.request.name),
            _detailRow(
              LocaleKeys.login_phone_label.tr(),
              widget.request.userName,
            ),
            _detailRow(LocaleKeys.profile_phone.tr(), widget.request.phone),
            _detailRow(LocaleKeys.profile_address.tr(), widget.request.address),
            _detailRow(
              LocaleKeys.register_vehicle_type.tr(),
              widget.request.vehicleType,
            ),
            _detailRow(
              LocaleKeys.register_license_plate.tr(),
              widget.request.licensePlate,
            ),
            _detailRow(
              LocaleKeys.register_license_expiry.tr(),
              widget.request.licensePlateExpiredDate,
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.register_documents_title.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (final (title, url) in documents) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (url.isEmpty)
                Text(LocaleKeys.users_document_missing.tr())
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrl(url),
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => SizedBox(
                      height: 80,
                      child: Center(
                        child: Text(LocaleKeys.users_document_load_error.tr()),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSoft)),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}
