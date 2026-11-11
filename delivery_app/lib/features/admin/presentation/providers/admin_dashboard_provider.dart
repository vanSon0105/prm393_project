import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/admin/data/admin_dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(ref.watch(apiProviderProvider)),
);

final adminDashboardOverviewProvider = FutureProvider<AdminDashboardOverview>(
  (ref) => ref.watch(adminDashboardRepositoryProvider).getOverview(),
  retry: (retryCount, error) => null,
);
