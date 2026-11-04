import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/models/register_model.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';

abstract class AuthenticationRepository {
  Future<LoginModel> login({required LoginParam param});

  Future<RegisterModel> registerCustomerAccount(RegisterUserParam param);

  Future<RegisterModel> registerDriverAccount(RegisterDriverParam param);

  Future<VehicleTypeModel> getVehicleTypes();

  Future<Role> getRoles();
}
