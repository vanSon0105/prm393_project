import 'package:delivery_app/features/admin/presentation/screens/admin_home_page.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_provider.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Admin data stays in sync with Riverpod state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(appRouter.namedLocation(AppRoute.admin.rawValue), '/admin');
    expect(container.read(driverMetricsProvider).totalDrivers, 6);
    expect(container.read(driverMetricsProvider).pendingRequests, 3);

    container.read(driverSearchQueryProvider.notifier).update('59A1');
    expect(container.read(filteredDriversProvider).length, 1);

    container.read(driverRequestsProvider.notifier).approve('request-01');
    expect(container.read(driverRequestsProvider).length, 2);
    expect(container.read(driverMetricsProvider).pendingRequests, 2);
    expect(container.read(latestDriverRequestsProvider).length, 2);
  });

  testWidgets('Admin can switch between the three screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AdminHomePage())),
    );

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
  });
}
