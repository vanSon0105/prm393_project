import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';

class RegisterState {
  final Role currentRole;
  final List<VehicleTypeData> vehicles;
  final bool loadingVehicles;
  final bool submitting;
  final bool vehicleLoadFailed;

  RegisterState({
    required this.currentRole,
    this.vehicles = const [],
    this.loadingVehicles = false,
    this.submitting = false,
    this.vehicleLoadFailed = false,
  });

  bool get isDriver => currentRole == Role.driver;

  RegisterState copyWith({
    Role? role,
    List<VehicleTypeData>? vehicles,
    bool? loadingVehicles,
    bool? submitting,
    bool? vehicleLoadFailed,
  }) {
    return RegisterState(
      currentRole: role ?? currentRole,
      vehicles: vehicles ?? this.vehicles,
      loadingVehicles: loadingVehicles ?? this.loadingVehicles,
      submitting: submitting ?? this.submitting,
      vehicleLoadFailed: vehicleLoadFailed ?? this.vehicleLoadFailed,
    );
  }
}
