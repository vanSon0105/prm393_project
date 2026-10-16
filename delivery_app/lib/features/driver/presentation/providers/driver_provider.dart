import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/driver_remote_datasource.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/driver_repository.dart';

class DriverMetrics {
  const DriverMetrics({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.pendingRequests,
  });

  final int totalDrivers;
  final int activeDrivers;
  final int pendingRequests;
}

final driverRemoteDataSourceProvider = Provider<DriverRemoteDataSource>((ref) {
  return const DriverRemoteDataSource();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepositoryImpl(ref.watch(driverRemoteDataSourceProvider));
});

final driversProvider = Provider<List<Driver>>((ref) {
  return ref.watch(driverRepositoryProvider).getDrivers();
});

class DriverSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final driverSearchQueryProvider = NotifierProvider<DriverSearchQuery, String>(
  DriverSearchQuery.new,
);

final filteredDriversProvider = Provider<List<Driver>>((ref) {
  final query = ref.watch(driverSearchQueryProvider).trim().toLowerCase();
  final drivers = ref.watch(driversProvider);
  if (query.isEmpty) return drivers;
  return drivers
      .where((driver) {
        return driver.name.toLowerCase().contains(query) ||
            driver.plateNumber.toLowerCase().contains(query);
      })
      .toList(growable: false);
});

class PendingDriverRequests extends Notifier<List<DriverAccountRequest>> {
  @override
  List<DriverAccountRequest> build() {
    return ref.watch(driverRepositoryProvider).getAccountRequests();
  }

  void approve(String requestId) => _remove(requestId);

  void reject(String requestId) => _remove(requestId);

  void _remove(String requestId) {
    state = state
        .where((request) => request.id != requestId)
        .toList(growable: false);
  }
}

final driverRequestsProvider =
    NotifierProvider<PendingDriverRequests, List<DriverAccountRequest>>(
      PendingDriverRequests.new,
    );

final topRatedDriversProvider = Provider<List<Driver>>((ref) {
  final drivers = [...ref.watch(driversProvider)];
  drivers.sort((a, b) => b.rating.compareTo(a.rating));
  return drivers.take(6).toList(growable: false);
});

final latestDriverRequestsProvider = Provider<List<DriverAccountRequest>>((
  ref,
) {
  final requests = [...ref.watch(driverRequestsProvider)];
  requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return requests.take(3).toList(growable: false);
});

final driverMetricsProvider = Provider<DriverMetrics>((ref) {
  final drivers = ref.watch(driversProvider);
  final requests = ref.watch(driverRequestsProvider);
  return DriverMetrics(
    totalDrivers: drivers.length,
    activeDrivers: drivers
        .where((driver) => driver.status != DriverStatus.offline)
        .length,
    pendingRequests: requests.length,
  );
});
