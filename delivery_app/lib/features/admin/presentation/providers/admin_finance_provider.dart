import 'package:delivery_app/data/network/base/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_finance_remote_repository.dart';
import '../../domain/entities/admin_finance.dart';
import '../../domain/repositories/admin_finance_repository.dart';

final adminFinanceRepositoryProvider = Provider<AdminFinanceRepository>((ref) {
  return AdminFinanceRemoteRepository(ref.watch(apiProviderProvider));
});

final adminBankAccountProvider = FutureProvider<AdminBankAccount?>((ref) {
  return ref.watch(adminFinanceRepositoryProvider).getBankAccount();
}, retry: _noAutomaticRetry);

final adminTopUpRequestsProvider = FutureProvider<List<DriverTopUpRequest>>((
  ref,
) {
  return ref.watch(adminFinanceRepositoryProvider).getTopUpRequests();
}, retry: _noAutomaticRetry);

Duration? _noAutomaticRetry(int retryCount, Object error) => null;

class AdminFinanceActions extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  Future<void> updateBankAccount(AdminBankAccount account) async {
    if (state.contains('bank')) {
      throw StateError('Bank update already in progress');
    }
    state = {...state, 'bank'};
    try {
      await ref.read(adminFinanceRepositoryProvider).updateBankAccount(account);
      ref.invalidate(adminBankAccountProvider);
    } finally {
      state = {...state}..remove('bank');
    }
  }

  Future<void> review({
    required int requestId,
    required bool approved,
    String reason = '',
  }) async {
    final key = 'request-$requestId';
    if (state.contains(key)) {
      throw StateError('Top-up review already in progress');
    }
    state = {...state, key};
    try {
      await ref
          .read(adminFinanceRepositoryProvider)
          .reviewTopUpRequest(
            requestId: requestId,
            approved: approved,
            reason: reason,
          );
      ref.invalidate(adminTopUpRequestsProvider);
    } finally {
      state = {...state}..remove(key);
    }
  }
}

final adminFinanceActionsProvider =
    NotifierProvider<AdminFinanceActions, Set<String>>(AdminFinanceActions.new);
