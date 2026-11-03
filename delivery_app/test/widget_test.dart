import 'package:delivery_app/features/admin/presentation/screens/admin_home_page.dart';
import 'package:delivery_app/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:delivery_app/features/admin/presentation/widgets/user_card.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_earnings_provider.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_provider.dart';
import 'package:delivery_app/features/driver/domain/entities/admin_driver.dart';
import 'package:delivery_app/features/driver/domain/entities/admin_driver_request.dart';
import 'package:delivery_app/features/driver/domain/repositories/admin_driver_repository.dart';
import 'package:delivery_app/features/setting/setting_provider.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  test('Admin data stays in sync with Riverpod state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(appRouter.namedLocation(AppRoute.admin.rawValue), '/admin');
    expect(
      appRouter.namedLocation(AppRoute.driverEarnings.rawValue),
      '/driver-earnings',
    );
    expect(container.read(driverMetricsProvider).totalDrivers, 6);
    expect(container.read(driverMetricsProvider).pendingRequests, 3);

    container.read(driverSearchQueryProvider.notifier).update('59A1');
    expect(container.read(filteredDriversProvider).length, 1);

    container.read(driverRequestsProvider.notifier).approve('request-01');
    expect(container.read(driverRequestsProvider).length, 2);
    expect(container.read(driverMetricsProvider).pendingRequests, 2);
    expect(container.read(latestDriverRequestsProvider).length, 2);
  });

  test('Ported UI state is managed by Riverpod', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingUiProvider.notifier).selectLanguage('ko-KR');
    expect(container.read(settingUiProvider).selectedLanguage, 'ko-KR');

    container.read(driverEarningsProvider.notifier).selectFilter('30 ngày');
    expect(container.read(driverEarningsProvider).selectedFilter, '30 ngày');

    container.read(adminUsersProvider.notifier).selectRole('Khách hàng');
    expect(container.read(adminUsersProvider).filteredUsers.length, 3);

    container.read(adminUsersProvider.notifier).updateSearch('phammai');
    expect(
      container.read(adminUsersProvider).filteredUsers.single.name,
      'Phạm Mai',
    );

    container
        .read(adminUsersProvider.notifier)
        .toggleStatus('phammai@gmail.com');
    expect(
      container.read(adminUsersProvider).filteredUsers.single.isActive,
      isFalse,
    );
  });

  testWidgets('Admin can switch between the four screens', (tester) async {
    final adminRepository = _TestAdminDriverRepository();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: JsonAssetLoader(),
        child: Builder(
          builder: (context) => ProviderScope(
            overrides: [
              adminDriverRepositoryProvider.overrideWithValue(adminRepository),
              adminDriversProvider.overrideWith(
                (ref) async => const [
                  AdminDriver(
                    id: 1,
                    name: 'Trần Anh',
                    phone: '0901234567',
                    address: 'Quận 1',
                    avatarUrl: '',
                    documents: DriverDocuments(
                      licenseFrontUrl: '',
                      licenseBackUrl: '',
                      identityFrontUrl: '',
                      identityBackUrl: '',
                    ),
                  ),
                  AdminDriver(
                    id: 2,
                    name: 'Lê Hoàng',
                    phone: '0918821204',
                    address: 'Quận 3',
                    avatarUrl: '',
                  ),
                ],
              ),
            ],
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const AdminHomePage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-nav-drivers')));
    await tester.pumpAndSettle();
    expect(find.text('Driver list'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0901');
    await tester.pump();
    expect(find.text('Trần Anh'), findsOneWidget);
    expect(find.text('Lê Hoàng'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin-nav-requests')));
    await tester.pumpAndSettle();
    expect(find.text('Account opening\nrequests'), findsOneWidget);

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').last);
    await tester.pumpAndSettle();
    expect(find.text('Đỗ Quang Huy'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin-nav-users')));
    await tester.pump();
    expect(find.text('User management'), findsOneWidget);
    expect(find.text('6 users'), findsOneWidget);

    await tester.tap(find.byType(UserCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View information'));
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('trananh@gmail.com'), findsWidgets);
    expect(find.text('0912345678'), findsOneWidget);
    expect(find.text('Account role'), findsOneWidget);
    expect(find.text('Account status'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).at(2));
    await tester.pumpAndSettle();
    expect(find.text('2 users'), findsOneWidget);
    await tester.tap(find.byType(UserCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Lock account'), findsNothing);
    await tester.tap(find.text('View information'));
    await tester.pumpAndSettle();
    expect(find.text('Driver documents'), findsOneWidget);
    expect(find.text('Driving license - front'), findsOneWidget);
    expect(find.text('No image available'), findsWidgets);
  });
}

class _TestAdminDriverRepository implements AdminDriverRepository {
  final requests = <AdminDriverRequest>[
    const AdminDriverRequest(
      id: 8,
      name: 'Đỗ Quang Huy',
      phone: '0907712244',
      address: 'Quận 1',
      avatarUrl: '',
      licenseFrontUrl: '',
      licenseBackUrl: '',
      identityFrontUrl: '',
      identityBackUrl: '',
    ),
  ];

  @override
  Future<List<AdminDriver>> getDrivers() async => [];

  @override
  Future<List<AdminDriverRequest>> getRequests() async => [...requests];

  @override
  Future<void> reviewRequest({
    required int driverId,
    required bool approved,
    String reason = '',
  }) async {
    requests.removeWhere((request) => request.id == driverId);
  }
}
