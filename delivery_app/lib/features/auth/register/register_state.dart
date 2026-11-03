import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';

class RegisterState {
  final Role currentRole;
  final List<VehicleTypeData> vehicles;
  final VehicleTypeData? vehicleTypeDataSelected;

  RegisterState({
    required this.currentRole,
    required this.vehicles,
    this.vehicleTypeDataSelected,
  });

  bool get isDriver => currentRole == Role.driver;

  RegisterState copyWidth({
    Role? role,
    List<VehicleTypeData>? vehicles,
    VehicleTypeData? vehicle,
  }) {
    return RegisterState(
      currentRole: role ?? currentRole,
      vehicles: vehicles ?? this.vehicles,
      vehicleTypeDataSelected: vehicle ?? vehicleTypeDataSelected,
    );
  }
}
