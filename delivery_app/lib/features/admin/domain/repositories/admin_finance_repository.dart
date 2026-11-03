import '../entities/admin_finance.dart';

abstract class AdminFinanceRepository {
  Future<AdminBankAccount?> getBankAccount();
  Future<void> updateBankAccount(AdminBankAccount account);
  Future<List<DriverTopUpRequest>> getTopUpRequests();
  Future<void> reviewTopUpRequest({
    required int requestId,
    required bool approved,
    String reason = '',
  });
}
