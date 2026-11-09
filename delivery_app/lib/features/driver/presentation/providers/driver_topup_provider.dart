import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/driver_topup_repository.dart';

final driverTopupRepositoryProvider = Provider<DriverTopupRepository>(
  (ref) => DriverTopupRepository(ref.watch(apiProviderProvider)),
);

final driverTopupBankProvider = FutureProvider<DriverTopupBank>(
  (ref) => ref.watch(driverTopupRepositoryProvider).getAdminBank(),
  retry: _noRetry,
);

final driverTopupRequestsProvider = FutureProvider<List<DriverTopupRequest>>((
  ref,
) {
  final driverId = ref.watch(
    appViewModelProvider.select((app) => app.profileId),
  );
  if (driverId == null || driverId <= 0) {
    throw StateError('Driver ID is unavailable');
  }
  return ref.watch(driverTopupRepositoryProvider).getRequests(driverId);
}, retry: _noRetry);

Duration? _noRetry(int retryCount, Object error) => null;

class DriverTopupAction extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> submit({
    required int amount,
    required String fileName,
    required List<int> imageBytes,
    int? requestId,
  }) async {
    if (state) return;
    final driverId = ref.read(appViewModelProvider).profileId;
    if (driverId == null || driverId <= 0) {
      throw StateError('Driver ID is unavailable');
    }
    state = true;
    try {
      await ref
          .read(driverTopupRepositoryProvider)
          .submit(
            driverId: driverId,
            amount: amount,
            fileName: fileName,
            imageBytes: imageBytes,
            requestId: requestId,
          );
      ref.invalidate(driverTopupRequestsProvider);
    } finally {
      state = false;
    }
  }
}

final driverTopupActionProvider = NotifierProvider<DriverTopupAction, bool>(
  DriverTopupAction.new,
);
