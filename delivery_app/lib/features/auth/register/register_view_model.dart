import 'package:delivery_app/features/auth/register/register_state.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/data/models/register_model.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/location/location_service.dart';
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

  Future<RegisterModel> register(RegisterAccountRequest request) async {
    if (state.submitting) throw StateError('Registration already in progress');
    state = state.copyWith(submitting: true);
    try {
      final repository = ref.read(authenticationRepositoryProvider);
      switch (request.role) {
        case Role.customer:
          return await repository.registerCustomerAccount(
            RegisterUserParam(
              fullName: request.fullName,
              userName: request.userName,
              password: request.password,
              phoneNumber: request.phoneNumber,
            ),
          );
        case Role.driver:
          if (request.vehicleId == null ||
              request.licensePlate?.trim().isEmpty != false ||
              request.licensePlateExpiredDate?.trim().isEmpty != false ||
              !{
                'driving_license_front_side',
                'driving_license_back_side',
                'front_side_of_the_identity_card',
                'the_back_of_the_identity_card',
              }.every(request.documents.containsKey)) {
            throw ArgumentError(
              'Driver vehicle and four documents are required',
            );
          }
          final coordinates = await ref
              .read(locationServiceProvider)
              .currentCoordinates();
          return await repository.registerDriverAccount(
            RegisterDriverParam(
              fullName: request.fullName,
              userName: request.userName,
              password: request.password,
              phoneNumber: request.phoneNumber,
              vehicleId: request.vehicleId!,
              licensePlate: request.licensePlate!,
              licensePlateExpiredDate: request.licensePlateExpiredDate!,
              latitude: coordinates.latitude,
              longitude: coordinates.longitude,
              documents: request.documents,
            ),
          );
        case Role.admin:
          throw ArgumentError('Admin registration is not supported');
      }
    } finally {
      if (ref.mounted) state = state.copyWith(submitting: false);
    }
  }
}
