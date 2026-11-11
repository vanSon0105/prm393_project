import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/driver/data/driver_wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverWalletRepositoryProvider = Provider<DriverWalletRepository>(
  (ref) => DriverWalletRepository(ref.watch(apiProviderProvider)),
);

final driverWalletBalanceProvider = FutureProvider.family<int, int>(
  (ref, driverId) =>
      ref.watch(driverWalletRepositoryProvider).getBalance(driverId),
  retry: (retryCount, error) => null,
);
