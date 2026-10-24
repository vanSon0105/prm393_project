import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/domain/repositories/authentication_repository.dart';

class AuthenticationRepositoryImpl extends AuthenticationRepository {
  final ApiProvider apiProvider;

  AuthenticationRepositoryImpl(this.apiProvider);

  @override
  Future<void> login() {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<void> registerAccount() {
    // TODO: implement registerAccount
    throw UnimplementedError();
  }
}
