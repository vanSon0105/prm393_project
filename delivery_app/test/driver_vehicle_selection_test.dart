import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/models/register_model.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/domain/repositories/authentication_repository.dart';
import 'package:delivery_app/features/auth/register/register_screen.dart';
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

  testWidgets('driver can load and select a vehicle type', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _VehicleRepository();
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
            ],
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const RegisterScreen(role: Role.driver),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.vehicleTypeCalls, 1);
    final dropdown = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    expect(find.text('BIKE'), findsOneWidget);
    expect(find.text('CAR_4_SEAT'), findsOneWidget);

    await tester.tap(find.text('BIKE'));
    await tester.pumpAndSettle();
    expect(tester.state<FormFieldState<int>>(dropdown).value, 1);
    expect(tester.takeException(), isNull);
  });
}

class _VehicleRepository implements AuthenticationRepository {
  int vehicleTypeCalls = 0;

  @override
  Future<VehicleTypeModel> getVehicleTypes() async {
    vehicleTypeCalls++;
    return VehicleTypeModel(
      data: [
        VehicleTypeData(id: 1, name: 'BIKE'),
        VehicleTypeData(id: 2, name: 'CAR_4_SEAT'),
      ],
    );
  }

  @override
  Future<LoginModel> login({required LoginParam param}) =>
      throw UnimplementedError();

  @override
  Future<RegisterAccountResult> registerAccount(
    RegisterAccountRequest request,
  ) => throw UnimplementedError();

  @override
  Future<RegisterModel> registerCustomerAccount(RegisterUserParam param) =>
      throw UnimplementedError();

  @override
  Future<RegisterModel> registerDriverAccount(RegisterDriverParam param) =>
      throw UnimplementedError();

  @override
  Future<Role> getRoles() => throw UnimplementedError();
}
