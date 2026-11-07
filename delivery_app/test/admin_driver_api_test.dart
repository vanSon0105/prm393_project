import 'dart:convert';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/driver/data/datasources/admin_driver_remote_datasource.dart';
import 'package:delivery_app/features/driver/domain/entities/admin_driver.dart';
import 'package:delivery_app/features/driver/domain/entities/admin_driver_request.dart';
import 'package:delivery_app/features/driver/domain/repositories/admin_driver_repository.dart';
import 'package:delivery_app/features/driver/presentation/providers/driver_provider.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_list_page.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_requests_page.dart';
import 'package:delivery_app/features/driver/presentation/widgets/admin_driver_request_card.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    Environment.configFlavor(FlavorValue.dev);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

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
                    'driving_license_front_url':
                        'http://localhost:8080/image/license-front.jpg',
                    'driving_license_back_url':
                        'http://localhost:8080/image/license-back.jpg',
                    'identity_card_front_url':
                        'http://localhost:8080/image/id-front.jpg',
                    'identity_card_back_url':
                        'http://localhost:8080/image/id-back.jpg',
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
    expect(
      drivers.single.documents?.licenseFrontUrl,
      endsWith('/image/license-front.jpg'),
    );
    expect(
      drivers.single.documents?.identityBackUrl,
      endsWith('/image/id-back.jpg'),
    );
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

  test(
    'loads requests and sends approval without reason or rejection with reason',
    () async {
      final calls = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add(options);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: options.method == 'GET'
                      ? [
                          {
                            'driver_id': 8,
                            'full_name': 'Nguyễn Văn A',
                            'phone_number': '0901234567',
                            'address': 'Quận 1',
                            'user_name': 'driver_a',
                            'vehicle_type': 'CAR_4_SEAT',
                            'license_plate': '59A1-12345',
                            'driving_license_front_url':
                                'http://localhost:8080/image/license.jpg',
                            'driving_license_back_url': '',
                            'identity_card_front_url': '',
                            'identity_card_back_url': '',
                          },
                        ]
                      : {
                          'data': {'driver_id': 8},
                        },
                ),
              );
            },
          ),
        );
      final source = AdminDriverRemoteDataSource(ApiProvider(dio));

      final requests = await source.fetchRequests();
      expect(calls.first.path, endsWith('/api/admin/drivers/requests'));
      expect(requests.single.licenseFrontUrl, endsWith('/image/license.jpg'));
      expect(requests.single.userName, 'driver_a');
      expect(requests.single.vehicleType, 'CAR_4_SEAT');
      expect(requests.single.licensePlate, '59A1-12345');

      await source.reviewRequest(driverId: 8, approved: true);
      expect(calls[1].method, 'POST');
      expect(calls[1].path, endsWith('/api/admin/drivers/8/approve'));
      expect(jsonDecode(calls[1].data as String), {
        'driver_id': 8,
        'status': true,
      });

      await source.reviewRequest(
        driverId: 8,
        approved: false,
        reason: '  Ảnh mờ  ',
      );
      expect(jsonDecode(calls[2].data as String), {
        'driver_id': 8,
        'status': false,
        'reason': 'Ảnh mờ',
      });
      await expectLater(
        source.reviewRequest(driverId: 8, approved: false, reason: '   '),
        throwsArgumentError,
      );
      expect(calls, hasLength(3));
    },
  );

  testWidgets('rejection requires a reason before calling the repository', (
    tester,
  ) async {
    final repository = _RecordingAdminDriverRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDriverRepositoryProvider.overrideWithValue(repository),
        ],
        child: _localizedApp(const Scaffold(body: DriverRequestsPage())),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(AdminDriverRequestCard), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    await tester.tap(find.text('View application'));
    await tester.pumpAndSettle();
    expect(find.text('driver_a'), findsOneWidget);
    expect(find.text('CAR_4_SEAT'), findsOneWidget);
    expect(find.text('59A1-12345'), findsOneWidget);
    expect(find.text('Driver documents'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();
    final rejectButton = find.widgetWithText(FilledButton, 'Reject');
    expect(tester.widget<FilledButton>(rejectButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Ảnh mờ  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(rejectButton).onPressed, isNotNull);
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();

    expect(repository.lastReason, 'Ảnh mờ');
    expect(repository.lastApproved, isFalse);
    expect(find.text('Nguyễn Văn A'), findsNothing);
  });
}

Widget _localizedApp(Widget home) => EasyLocalization(
  supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
  startLocale: const Locale('en', 'US'),
  fallbackLocale: const Locale('en', 'US'),
  path: 'resources/langs',
  assetLoader: JsonAssetLoader(),
  child: Builder(
    builder: (context) => MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: home,
    ),
  ),
);

class _RecordingAdminDriverRepository implements AdminDriverRepository {
  final requests = <AdminDriverRequest>[
    const AdminDriverRequest(
      id: 8,
      name: 'Nguyễn Văn A',
      phone: '0901234567',
      address: 'Quận 1',
      avatarUrl: '',
      licenseFrontUrl: '',
      licenseBackUrl: '',
      identityFrontUrl: '',
      identityBackUrl: '',
      userName: 'driver_a',
      vehicleType: 'CAR_4_SEAT',
      licensePlate: '59A1-12345',
    ),
  ];
  String? lastReason;
  bool? lastApproved;

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
    lastApproved = approved;
    lastReason = reason;
    requests.removeWhere((request) => request.id == driverId);
  }
}
