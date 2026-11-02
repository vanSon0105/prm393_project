import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/driver/data/datasources/admin_driver_remote_datasource.dart';
import 'package:delivery_app/features/driver/domain/entities/admin_driver.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_provider.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_list_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('loads and maps approved drivers from the admin API', () async {
    late RequestOptions request;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'driver_id': 8,
                    'full_name': 'Nguyễn Văn A',
                    'phone_number': '0901234567',
                    'address': 'Quận 1',
                    'avatar_url': 'http://localhost:8080/image/8.jpg',
                  },
                ],
              ),
            );
          },
        ),
      );

    final drivers = await AdminDriverRemoteDataSource(ApiProvider(dio))
        .fetchDrivers();

    expect(request.method, 'GET');
    expect(request.path, endsWith('/api/admin/drivers'));
    expect(drivers, hasLength(1));
    expect(drivers.single.id, 8);
    expect(drivers.single.name, 'Nguyễn Văn A');
    expect(drivers.single.phone, '0901234567');
  });

  testWidgets('admin Drivers tab shows API data and filters by phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDriversProvider.overrideWith(
            (ref) async => const [
              AdminDriver(
                id: 8,
                name: 'Nguyễn Văn A',
                phone: '0901234567',
                address: 'Quận 1',
                avatarUrl: '',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: DriverListPage())),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '999');
    await tester.pump();
    expect(find.text('Nguyễn Văn A'), findsNothing);

    await tester.enterText(find.byType(TextField), '0901');
    await tester.pump();
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
  });
}
