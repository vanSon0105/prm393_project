import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';

class LoginParam extends ApiParam {
  final String userName;
  final String password;
  final Role role;

  LoginParam({
    required this.userName,
    required this.password,
    required this.role,
  });

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {
    'user_name': userName,
    'password': password,
    'role': role.value,
  };

  @override
  String get path => '/api/user/login';
}
