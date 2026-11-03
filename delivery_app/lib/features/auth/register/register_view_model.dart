import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/register/register_state.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/repository_module.dart';
import '../../../widget/app_loading.dart';

part 'register_view_model.g.dart';

Duration? disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: disableRetry)
class RegisterViewModel extends _$RegisterViewModel {
  @override
  RegisterState build(Role role) {
    return RegisterState(currentRole: role, vehicles: []);
  }

  void changeRole(Role role) {
    debugPrint('----- currentRole: ${state.vehicles.map((e) => e.toJson())}');
    state = state.copyWidth(role: role);
  }

  void changeVehicle(VehicleTypeData? vehicle) {
    state = state.copyWidth(vehicle: vehicle);
  }

  Future<void> getVehicleType() async {
    try {
      AppLoading.instance.show();
      final api = ref.read(authenticationRepositoryProvider);
      final response = await api.getVehicleTypes();
      state = state.copyWidth(vehicles: response.data);
      debugPrint('------ getVehicle: ${state.vehicles.length}');
    } catch (e) {
      debugPrint('------ GetVehicle Error : $e');
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> registerAccount({
    String userName = '',
    String password = '',
    String phoneNumber = '',
    int? vehicleId,
    String licensePlate = '',
    String drivingLicenseFrontSide = '',
    String drivingLicenseBackSide = '',
    String frontSideOfTheIdentityCard = '',
    String backSideOfTheIdentityCard = '',
  }) async {
    try {
      AppLoading.instance.show();
      final api = ref.read(authenticationRepositoryProvider);
      String message = '';
      switch (state.currentRole) {
        case Role.admin:
          break;
        case Role.driver:
          if (vehicleId == null) {
            AppNavigate.instance.showAppDialog(
              message: 'Loại xe không được trống',
            );
            return;
          }
          final result = await api.registerDriverAccount(
            RegisterDriverParam(
              userName: userName,
              password: password,
              phoneNumber: phoneNumber,
              vehicleId: vehicleId,
              licensePlate: licensePlate,
              drivingLicenseFrontSide: drivingLicenseFrontSide,
              drivingLicenseBackSide: drivingLicenseBackSide,
              frontSideOfTheIdentityCard: frontSideOfTheIdentityCard,
              backSideOfTheIdentityCard: backSideOfTheIdentityCard,
            ),
          );
          message = result.data.message;
        case Role.customer:
          final result = await api.registerCustomerAccount(
            RegisterUserParam(
              userName: userName,
              password: password,
              phoneNumber: phoneNumber,
            ),
          );
          message = result.data.message;
      }
      AppNavigate.instance.showAppDialog(message: message);
    } catch (e) {
      debugPrint('------------- Register account error: ${e.toString()}');
    } finally {
      AppLoading.instance.dismiss();
    }
  }
}
