import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/driver_provider.dart';
import '../widgets/admin_driver_list_panel.dart';
import '../widgets/driver_directory_header.dart';
import '../widgets/driver_search_field.dart';

class DriverListPage extends ConsumerWidget {
  const DriverListPage({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(filteredAdminDriversProvider);

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
                        '${items.length} tài xế',
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Text(
                      'Đã phê duyệt',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tải lại',
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
                const Text(
                  'Không tải được danh sách tài xế. Kiểm tra kết nối API rồi thử lại.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(adminDriversProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
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
