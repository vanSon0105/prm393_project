import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'driver_resubmit_repository.dart';

final driverResubmitRepositoryProvider = Provider<DriverResubmitRepository>((
  ref,
) {
  return DriverResubmitRemoteRepository(ref.watch(apiProviderProvider));
});

final rejectedDriverRequestProvider = FutureProvider.autoDispose
    .family<RejectedDriverRequest, int>(
      (ref, driverId) =>
          ref.watch(driverResubmitRepositoryProvider).getRequest(driverId),
      retry: (count, error) => null,
    );

final driverResubmitVehiclesProvider = FutureProvider<List<VehicleTypeData>>(
  (ref) async =>
      (await ref.watch(authenticationRepositoryProvider).getVehicleTypes())
          .data ??
      [],
  retry: (count, error) => null,
);

class DriverResubmitActions extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  Future<void> submit(int driverId, DriverResubmitData data) async {
    if (state.contains(driverId)) {
      throw StateError('Driver resubmission already in progress');
    }
    state = {...state, driverId};
    try {
      await ref.read(driverResubmitRepositoryProvider).resubmit(driverId, data);
    } finally {
      state = {...state}..remove(driverId);
    }
  }
}

final driverResubmitActionsProvider =
    NotifierProvider<DriverResubmitActions, Set<int>>(
      DriverResubmitActions.new,
    );
