import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';

class RegisterState {
  final Role currentRole;
  final List<VehicleTypeData> vehicles;

  RegisterState({required this.currentRole, this.vehicles = const []});

  bool get isDriver => currentRole == Role.driver;

  RegisterState copyWidth({Role? role, List<VehicleTypeData>? vehicles}) {
    return RegisterState(
      currentRole: role ?? currentRole,
      vehicles: vehicles ?? this.vehicles,
    );
  }
}
