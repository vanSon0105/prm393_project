import 'package:delivery_app/features/auth/register/register_state.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/repository_module.dart';

part 'register_view_model.g.dart';

Duration? disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: disableRetry)
class RegisterViewModel extends _$RegisterViewModel {
  @override
  RegisterState build(Role role) {
    return RegisterState(currentRole: role);
  }

  Future<void> getVehicleType() async {
    state = state.copyWith(loadingVehicles: true, vehicleLoadFailed: false);
    try {
      final api = ref.read(authenticationRepositoryProvider);
      final response = await api.getVehicleTypes();
      if (!ref.mounted) return;
      final vehicles = response.data ?? [];
      state = state.copyWith(
        vehicles: vehicles,
        vehicleLoadFailed: vehicles.isEmpty,
      );
    } catch (_) {
      if (ref.mounted) state = state.copyWith(vehicleLoadFailed: true);
    } finally {
      if (ref.mounted) state = state.copyWith(loadingVehicles: false);
    }
  }

  Future<RegisterAccountResult> register(RegisterAccountRequest request) async {
    if (state.submitting) throw StateError('Registration already in progress');
    state = state.copyWith(submitting: true);
    try {
      return await ref
          .read(authenticationRepositoryProvider)
          .registerAccount(request);
    } finally {
      if (ref.mounted) state = state.copyWith(submitting: false);
    }
  }
}
