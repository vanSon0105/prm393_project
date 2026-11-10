import 'package:delivery_app/data/network/base/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/trip_history_model.dart';
import '../../data/repositories/trip_history_remote_repository.dart';

final tripHistoryRepositoryProvider = Provider<TripHistoryRemoteRepository>(
  (ref) => TripHistoryRemoteRepository(ref.watch(apiProviderProvider)),
);

final tripHistoryProvider = FutureProvider.family<TripHistoryPageData, int>(
  (ref, profileId) =>
      ref.watch(tripHistoryRepositoryProvider).getHistory(profileId: profileId),
  retry: (retryCount, error) => null,
);
