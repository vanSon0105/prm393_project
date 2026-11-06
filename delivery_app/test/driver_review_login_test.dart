import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/models/register_model.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/domain/repositories/authentication_repository.dart';
import 'package:delivery_app/features/auth/login/login_page.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_provider.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_repository.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_screen.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    AppLoading.instance.configLoading();
  });

  testWidgets('approved driver enters the app; rejected driver can resubmit', (
    tester,
  ) async {
    final repository = _DriverReviewRepository();
    final resubmitRepository = _RejectedRequestRepository();
    final router = GoRouter(
      navigatorKey: AppNavigate.instance.key,
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          name: '/login',
          builder: (_, _) => const LoginPage(),
        ),
        GoRoute(
          path: '/map',
          name: '/map',
          builder: (_, _) => const Scaffold(body: Text('Driver map')),
        ),
        GoRoute(
          path: '/driver/:driverId/resubmit',
          name: '/driver/:driverId/resubmit',
          builder: (_, state) => DriverResubmitScreen(
            driverId: int.parse(state.pathParameters['driverId']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: JsonAssetLoader(),
        saveLocale: false,
        child: Builder(
          builder: (context) => ProviderScope(
            overrides: [
              authenticationRepositoryProvider.overrideWithValue(repository),
              driverResubmitRepositoryProvider.overrideWithValue(
                resubmitRepository,
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => FlutterEasyLoading(child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'approved_driver');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Driver map'), findsOneWidget);
    expect(repository.lastRole, Role.driver);

    router.go('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'rejected_driver');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Reason: Document is unclear'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);
    expect(find.text('Driver map'), findsNothing);
    await tester.tap(find.text('Send for review again'));
    await tester.pumpAndSettle();
    expect(resubmitRepository.saved?.phoneNumber, '0901234567');
    expect(resubmitRepository.saved?.vehicleId, 1);
    expect(find.text('Application sent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DriverReviewRepository implements AuthenticationRepository {
  Role? lastRole;

  @override
  Future<RegisterModel> registerCustomerAccount(RegisterUserParam param) =>
      throw UnimplementedError();

  @override
  Future<RegisterModel> registerDriverAccount(RegisterDriverParam param) =>
      throw UnimplementedError();

  @override
  Future<LoginModel> login({required LoginParam param}) async {
    lastRole = param.role;
    final rejected = param.userName == 'rejected_driver';
    return LoginModel(
      data: LoginData(
        profileId: rejected ? 8 : 7,
        userName: param.userName,
        role: 'DRIVER',
        status: rejected ? 'REJECTED' : 'APPROVED',
        message: rejected ? 'Document is unclear' : 'Welcome',
      ),
    );
  }

  @override
  Future<VehicleTypeModel> getVehicleTypes() async =>
      VehicleTypeModel(data: [VehicleTypeData(id: 1, name: 'Motorbike')]);

  @override
  Future<Role> getRoles() => throw UnimplementedError();
}

class _RejectedRequestRepository implements DriverResubmitRepository {
  DriverResubmitData? saved;

  @override
  Future<RejectedDriverRequest> getRequest(int driverId) async =>
      RejectedDriverRequest(
        driverId: driverId,
        phoneNumber: '0901234567',
        vehicleId: 1,
        licensePlate: '59A1-12345',
        reason: 'Document is unclear',
        documentUrls: const {
          'front_side_of_the_identity_card': 'http://bad-ip/image/id-front.jpg',
          'the_back_of_the_identity_card': 'http://bad-ip/image/id-back.jpg',
          'driving_license_front_side': 'http://bad-ip/image/license-front.jpg',
          'driving_license_back_side': 'http://bad-ip/image/license-back.jpg',
        },
      );

  @override
  Future<void> resubmit(int driverId, DriverResubmitData data) async {
    saved = data;
  }
}
