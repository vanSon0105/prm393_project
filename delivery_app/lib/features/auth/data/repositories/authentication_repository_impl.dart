import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/vehicle_param.dart';
import 'package:delivery_app/features/auth/domain/repositories/authentication_repository.dart';

import '../../domain/entities/role.dart';

class AuthenticationRepositoryImpl extends AuthenticationRepository {
  final ApiProvider apiProvider;

  AuthenticationRepositoryImpl(this.apiProvider);

  @override
  Future<LoginModel> login({required LoginParam param}) async {
    final response = await apiProvider.requestApi(param: param);
    return LoginModel.fromJson(response);
  }

  @override
  Future<VehicleTypeModel> getVehicleTypes() async {
    final response = await apiProvider.requestApi(param: VehicleParam());
    return VehicleTypeModel.fromJson(response);
  }

  @override
  Future<void> registerAccount() {
    // TODO: implement registerAccount
    throw UnimplementedError();
  }

  @override
  Future<Role> getRoles() async {
    throw UnimplementedError();
  }
}
