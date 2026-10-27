import 'package:delivery_app/features/auth/domain/entities/role.dart';

abstract class AuthenticationRepository {
  Future<void> login();

  Future<void> registerAccount();

  Future<Role> getRoles();
}
