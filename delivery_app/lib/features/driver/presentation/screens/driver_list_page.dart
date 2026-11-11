import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/driver_provider.dart';
import '../widgets/admin_driver_list_panel.dart';
import '../widgets/driver_directory_header.dart';
import '../widgets/driver_search_field.dart';

class DriverListPage extends ConsumerWidget {
  const DriverListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(filteredAdminDriversProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DriverDirectoryHeader(),
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DriverSearchField(
            onChanged: ref.read(driverSearchQueryProvider.notifier).update,
          ),
        ),
        const SizedBox(height: 28),
        drivers.when(
          data: (items) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleKeys.admin_driver_count.tr(
                          namedArgs: {'count': '${items.length}'},
                        ),
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      LocaleKeys.admin_approved.tr(),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.admin_refresh.tr(),
                      onPressed: () => ref.invalidate(adminDriversProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AdminDriverListPanel(drivers: items),
              ],
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(LocaleKeys.admin_driver_load_error.tr()),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(adminDriversProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(LocaleKeys.admin_try_again.tr()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
