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

  testWidgets('admin can edit bank details and confirm a top-up', (
    tester,
  ) async {
    final repository = _FinanceRepository();
    await tester.pumpWidget(_app(const AdminBankAccountPage(), repository));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Example Bank'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
    await tester.tap(find.text('Save bank details'));
    await tester.pumpAndSettle();
    expect(repository.saved?.accountNumber, '9876543210');

    await tester.pumpWidget(_app(const AdminTopUpRequestsPage(), repository));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('50,000 ₫'), findsOneWidget);
    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    expect(repository.reviewedId, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.reviewedId, isNull);

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').last);
    await tester.pumpAndSettle();
    expect(repository.reviewedId, 7);
    expect(repository.approved, isTrue);
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

class _FinanceRepository implements AdminFinanceRepository {
  AdminBankAccount? saved;
  int? reviewedId;
  bool? approved;

  @override
  Future<AdminBankAccount?> getBankAccount() async => const AdminBankAccount(
    bankName: 'Example Bank',
    accountNumber: '1234567890',
    accountHolder: 'TEAM',
  );

  @override
  Future<void> updateBankAccount(AdminBankAccount account) async {
    saved = account;
  }

  @override
  Future<List<DriverTopUpRequest>> getTopUpRequests() async => [
    DriverTopUpRequest(
      id: 7,
      driverId: 5,
      driverName: 'Driver A',
      amount: 50000,
      createdAt: DateTime.utc(2026, 11, 3),
      status: TopUpStatus.pending,
    ),
  ];

  @override
  Future<void> reviewTopUpRequest({
    required int requestId,
    required bool approved,
    String reason = '',
  }) async {
    reviewedId = requestId;
    this.approved = approved;
  }
}
