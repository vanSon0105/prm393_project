import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/driver_provider.dart';
import '../widgets/driver_directory_header.dart';
import '../widgets/driver_list_panel.dart';
import '../widgets/driver_search_field.dart';

class DriverListPage extends ConsumerWidget {
  const DriverListPage({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(filteredDriversProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverDirectoryHeader(onBack: onBack),
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DriverSearchField(
            onChanged: ref.read(driverSearchQueryProvider.notifier).update,
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${drivers.length} tài xế',
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const Text(
                'Đang hoạt động',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DriverListPanel(
            drivers: drivers,
            mode: DriverListPanelMode.directory,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
