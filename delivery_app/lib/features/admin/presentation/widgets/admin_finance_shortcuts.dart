import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminFinanceShortcuts extends StatelessWidget {
  const AdminFinanceShortcuts({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Shortcut(
        icon: Icons.account_balance_outlined,
        title: LocaleKeys.admin_bank_title.tr(),
        subtitle: LocaleKeys.admin_bank_shortcut.tr(),
        onTap: () => context.push(AppRoute.adminBankAccount.rawValue),
      ),
      const SizedBox(height: 12),
      _Shortcut(
        icon: Icons.account_balance_wallet_outlined,
        title: LocaleKeys.admin_top_up_title.tr(),
        subtitle: LocaleKeys.admin_top_up_shortcut.tr(),
        onTap: () => context.push(AppRoute.adminTopUpRequests.rawValue),
      ),
    ],
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.surface),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
