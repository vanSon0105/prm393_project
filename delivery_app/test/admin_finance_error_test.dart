import 'package:delivery_app/data/network/base/exception.dart';
import 'package:delivery_app/features/admin/domain/entities/admin_finance.dart';
import 'package:delivery_app/features/admin/domain/repositories/admin_finance_repository.dart';
import 'package:delivery_app/features/admin/presentation/providers/admin_finance_provider.dart';
import 'package:delivery_app/features/admin/presentation/screens/admin_bank_account_page.dart';
import 'package:delivery_app/features/admin/presentation/screens/admin_top_up_requests_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('missing finance endpoints show an error without retrying', (
    tester,
  ) async {
    final repository = _MissingFinanceRepository();
    await tester.pumpWidget(_app(const AdminBankAccountPage(), repository));
    await tester.pumpAndSettle();

    expect(
      find.text('The finance API is not available on this server yet.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.bankCalls, 1);

    await tester.pumpWidget(_app(const AdminTopUpRequestsPage(), repository));
    await tester.pumpAndSettle();

    expect(
      find.text('The finance API is not available on this server yet.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.requestCalls, 1);
  });
}

Widget _app(Widget home, AdminFinanceRepository repository) => EasyLocalization(
  supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
  startLocale: const Locale('en', 'US'),
  fallbackLocale: const Locale('en', 'US'),
  path: 'resources/langs',
  assetLoader: JsonAssetLoader(),
  child: Builder(
    builder: (context) => ProviderScope(
      overrides: [adminFinanceRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: home,
      ),
    ),
  ),
);

class _MissingFinanceRepository implements AdminFinanceRepository {
  int bankCalls = 0;
  int requestCalls = 0;

  @override
  Future<AdminBankAccount?> getBankAccount() async {
    bankCalls++;
    throw ApiException(url: '/api/admin/bank-account', httpCode: 404);
  }

  @override
  Future<List<DriverTopUpRequest>> getTopUpRequests() async {
    requestCalls++;
    throw ApiException(url: '/api/admin/top-up-requests', httpCode: 404);
  }

  @override
  Future<void> updateBankAccount(AdminBankAccount account) =>
      throw UnimplementedError();

  @override
  Future<void> reviewTopUpRequest({
    required int requestId,
    required bool approved,
    String reason = '',
  }) => throw UnimplementedError();
}
