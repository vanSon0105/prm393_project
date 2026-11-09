import 'package:delivery_app/data/network/base/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiProviderProvider)),
);

final userProfileProvider = FutureProvider.family<UserProfile, int>(
  (ref, id) => ref.watch(profileRepositoryProvider).getProfile(id),
  retry: (retryCount, error) => null,
);
