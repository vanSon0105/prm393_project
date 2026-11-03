import 'package:delivery_app/data/network/base/param.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/role.dart';

class RegisterUserParam extends ApiParam {
  final String userName;
  final String password;
  final String phoneNumber;

  RegisterUserParam({
    required this.userName,
    required this.password,
    required this.phoneNumber,
  });

  @override
  String get path => '/api/user/register';

  @override
  Future<FormData> get formData async {
    return FormData.fromMap({
      'user_name': userName,
      'password': password,
      'role': Role.customer.value,
    });
  }
}
