abstract class AuthenticationRepository {
  Future<void> login();

  Future<void> registerAccount();
}
