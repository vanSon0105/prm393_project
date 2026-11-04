import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/models/register_model.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/data/repositories/vehicle_param.dart';
import 'package:delivery_app/features/auth/domain/repositories/authentication_repository.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/role.dart';

class AuthenticationRepositoryImpl extends AuthenticationRepository {
  final ApiProvider apiProvider;
  final Dio dio;

  AuthenticationRepositoryImpl(this.apiProvider, this.dio);

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
  Future<RegisterModel> registerCustomerAccount(RegisterUserParam param) async {
    final response = await apiProvider.requestApi(param: param);
    return RegisterModel.fromJson(response);
  }

  @override
  Future<RegisterModel> registerDriverAccount(RegisterDriverParam param) async {
    final response = await apiProvider.requestApi(param: param);
    return RegisterModel.fromJson(response);
  }

  @override
  Future<RegisterAccountResult> registerAccount(
    RegisterAccountRequest request,
  ) async {
    if (request.role == Role.admin) {
      throw ArgumentError('Admin registration is not supported');
    }
    if (request.role == Role.driver &&
        (request.vehicleId == null ||
            request.licensePlate == null ||
            request.documents.length != 4)) {
      throw ArgumentError('Driver vehicle and four documents are required');
    }

    final fields = <String, dynamic>{
      'full_name': request.fullName.trim(),
      'user_name': request.userName.trim(),
      'password': request.password,
      'role': request.role.value,
      'phone_number': request.phoneNumber.replaceAll(' ', ''),
    };
    if (request.role == Role.driver) {
      fields['vehicle_id'] = request.vehicleId.toString();
      fields['license_plate'] = request.licensePlate!.trim();
      for (final entry in request.documents.entries) {
        fields[entry.key] = MultipartFile.fromBytes(
          entry.value.bytes,
          filename: entry.value.name,
        );
      }
    }

    final response = await dio.post<dynamic>(
      '/api/user/register',
      data: FormData.fromMap(fields),
      options: Options(extra: const {'skipApiErrorDialog': true}),
    );
    final body = response.data;
    if (body is! Map || body['data'] is! Map) {
      throw const FormatException('Invalid registration response');
    }
    return RegisterAccountResult.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  @override
  Future<Role> getRoles() async {
    throw UnimplementedError();
  }
}
