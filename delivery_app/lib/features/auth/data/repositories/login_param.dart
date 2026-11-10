import 'package:delivery_app/data/network/base/param.dart';

class LoginParam extends ApiParam {
  final String userName;
  final String password;

  LoginParam({required this.userName, required this.password});

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {
    'user_name': userName,
    'password': password,
  };

  @override
  String get path => '/api/user/login';
}
