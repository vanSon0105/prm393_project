import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';

abstract class AuthenticationRepository {
  Future<LoginModel> login({required LoginParam param});

  Future<void> registerAccount();

  Future<Role> getRoles();
}
