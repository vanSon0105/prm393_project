import 'package:delivery_app/data/local/sharepreference/share_preference_repository.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/data/network/repository/repository.dart';
import 'package:delivery_app/data/network/repository/repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_module.g.dart';

@Riverpod(keepAlive: true)
ApiRepository apiRepository(Ref ref) {
  final apiProvider = ref.watch(apiProviderProvider);
  return ApiRepositoryImpl(apiProvider: apiProvider);
}

@Riverpod(keepAlive: true)
SharePreferenceRepository appSharePreferences(Ref ref) {
  throw UnimplementedError();
}
