import 'package:delivery_app/data/network/base/param.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/role.dart';

class RegisterUserParam extends ApiParam {
  final String fullName;
  final String userName;
  final String password;
  final String phoneNumber;

  RegisterUserParam({
    required this.fullName,
    required this.userName,
    required this.password,
    required this.phoneNumber,
  });

  @override
  String get method => Method.post;

  @override
  String get path => '/api/user/register';

  @override
  String get contentType => HeaderContentType.multipartFormData;

  @override
  bool get useMultipart => true;

  @override
  Map<String, dynamic> get extra => const {'skipApiErrorDialog': true};

  @override
  Future<FormData> get formData async {
    return FormData.fromMap({
      'full_name': fullName.trim(),
      'user_name': userName.trim(),
      'password': password,
      'phone_number': phoneNumber.replaceAll(' ', ''),
      'role': Role.customer.value,
    });
  }
}
