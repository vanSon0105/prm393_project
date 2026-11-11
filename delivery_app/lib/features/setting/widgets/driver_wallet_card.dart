import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_wallet_provider.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverWalletCard extends ConsumerWidget {
  const DriverWalletCard({required this.driverId, super.key});

  final int driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(driverWalletBalanceProvider(driverId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.blue,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LocaleKeys.settings_driver_wallet_balance.tr()),
                  const SizedBox(height: 4),
                  balance.when(
                    data: (amount) => Text(
                      _formatVnd(amount),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    loading: () => const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => Text(
                      LocaleKeys.settings_driver_wallet_error.tr(),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  ref.invalidate(driverWalletBalanceProvider(driverId)),
              tooltip: LocaleKeys.settings_driver_wallet_refresh.tr(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVnd(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '${amount < 0 ? '-' : ''}$buffer ₫';
  }
}
