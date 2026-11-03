import 'package:delivery_app/features/app_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth/domain/entities/role.dart';

part 'app_view_model.g.dart';

Duration? disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: disableRetry, keepAlive: true)
class AppViewModel extends _$AppViewModel {
  @override
  AppState build() {
    return AppState();
  }

  void updateAppData(Role role) {
    state = state.copyWith(role: role);
  }

  void clearData() {
    state = AppState();
  }
}
