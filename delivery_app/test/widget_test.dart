import 'package:delivery_app/features/admin/presentation/screens/admin_home_page.dart';
import 'package:delivery_app/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_earnings_provider.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_provider.dart';
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

    container.read(adminUsersProvider.notifier).selectRole('Tài xế');
    expect(container.read(adminUsersProvider).filteredUsers.length, 2);

    container.read(adminUsersProvider.notifier).updateSearch('lehoang');
    expect(
      container.read(adminUsersProvider).filteredUsers.single.name,
      'Lê Hoàng',
    );

    container
        .read(adminUsersProvider.notifier)
        .toggleStatus('lehoang@gmail.com');
    expect(
      container.read(adminUsersProvider).filteredUsers.single.isActive,
      isTrue,
    );
  });

  testWidgets('Admin can switch between the four screens', (tester) async {
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

    expect(find.text('Vận hành'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-nav-drivers')));
    await tester.pump();
    expect(find.text('Danh sách tài xế'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '59A1');
    await tester.pump();
    expect(find.text('Trần Anh'), findsOneWidget);
    expect(find.text('Lê Hoàng'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin-nav-requests')));
    await tester.pump();
    expect(find.text('Yêu cầu mở\ntài khoản'), findsOneWidget);

    await tester.tap(find.text('Duyệt').first);
    await tester.pump();
    expect(find.text('Đỗ Quang Huy'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin-nav-users')));
    await tester.pump();
    expect(find.text('User management'), findsOneWidget);
    expect(find.text('6 users'), findsOneWidget);
  });
}
