import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/app_user.dart';

class UserDetailsSheet extends StatelessWidget {
  const UserDetailsSheet({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: user.documents == null
          ? null
          : MediaQuery.sizeOf(context).height * .85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.users_view_info.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                InitialsAvatar(label: user.initials, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            _detailRow(context, LocaleKeys.profile_full_name.tr(), user.name),
            _detailRow(context, LocaleKeys.users_username.tr(), user.username),
            if (user.phone.isNotEmpty)
              _detailRow(context, LocaleKeys.profile_phone.tr(), user.phone),
            if (user.address.isNotEmpty)
              _detailRow(
                context,
                LocaleKeys.profile_address.tr(),
                user.address,
              ),
            _detailRow(context, LocaleKeys.profile_role.tr(), _roleLabel()),
            if (user.documents case final documents?) ...[
              const Divider(height: 24),
              Text(
                LocaleKeys.users_driver_documents.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _documentImage(
                context,
                LocaleKeys.users_license_front.tr(),
                documents.licenseFrontUrl,
              ),
              _documentImage(
                context,
                LocaleKeys.users_license_back.tr(),
                documents.licenseBackUrl,
              ),
              _documentImage(
                context,
                LocaleKeys.users_identity_front.tr(),
                documents.identityFrontUrl,
              ),
              _documentImage(
                context,
                LocaleKeys.users_identity_back.tr(),
                documents.identityBackUrl,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _documentImage(BuildContext context, String title, String url) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (url.isEmpty)
              Text(LocaleKeys.users_document_missing.tr())
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: double.infinity,
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
          ],
        ),
      );

  String _roleLabel() => switch (user.role) {
    'CUSTOMER' => LocaleKeys.users_role_customer.tr(),
    'DRIVER' => LocaleKeys.users_role_driver.tr(),
    'ADMIN' => LocaleKeys.users_role_admin.tr(),
    _ => user.role,
  };

  Widget _detailRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSoft)),
            const SizedBox(height: 5),
            SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
