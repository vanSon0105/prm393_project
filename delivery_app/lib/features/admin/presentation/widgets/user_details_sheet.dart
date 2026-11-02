import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../driver/domain/entities/admin_driver.dart';
import '../../domain/entities/app_user.dart';

class UserDetailsSheet extends StatelessWidget {
  const UserDetailsSheet({required this.user, this.driver, super.key});

  final AppUser user;
  final AdminDriver? driver;

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isActive ? AppColors.success : AppColors.danger;

    return SafeArea(
      child: SizedBox(
        height: driver == null ? null : MediaQuery.sizeOf(context).height * .85,
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
              if (user.email.isNotEmpty)
                _detailRow(context, LocaleKeys.profile_email.tr(), user.email),
              _detailRow(context, LocaleKeys.profile_phone.tr(), user.phone),
              if (user.address.isNotEmpty)
                _detailRow(
                  context,
                  LocaleKeys.profile_address.tr(),
                  user.address,
                ),
              _detailRow(context, LocaleKeys.profile_role.tr(), _roleLabel()),
              _detailRow(
                context,
                LocaleKeys.users_account_status.tr(),
                user.isActive
                    ? LocaleKeys.users_active.tr()
                    : LocaleKeys.users_locked.tr(),
                valueColor: statusColor,
              ),
              if (driver?.documents case final documents?) ...[
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
  }

  Widget _documentImage(BuildContext context, String title, String url) {
    return Padding(
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
  }

  String _roleLabel() => switch (user.role) {
    'Khách hàng' => LocaleKeys.users_role_customer.tr(),
    'Tài xế' => LocaleKeys.users_role_driver.tr(),
    'Admin' => LocaleKeys.users_role_admin.tr(),
    _ => user.role,
  };

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSoft)),
          const SizedBox(height: 5),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: valueColor ?? AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
