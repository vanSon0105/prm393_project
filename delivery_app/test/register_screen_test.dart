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

  testWidgets('customer registration validates fields and submits the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _RecordingRepository();
    await _pumpRegisterScreen(tester, repository, Role.customer);
    expect(tester.takeException(), isNull);

    expect(find.text('Driver documents'), findsNothing);
    final submit = find.widgetWithText(ElevatedButton, 'Create account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(repository.submitted, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nguyen Van A');
    await tester.enterText(fields.at(1), 'new_customer');
    await tester.enterText(fields.at(2), '0901234567');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'secret123');

    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.submitted?.role, Role.customer);
    expect(repository.submitted?.fullName, 'Nguyen Van A');
    expect(repository.submitted?.userName, 'new_customer');
    expect(repository.submitted?.documents, isEmpty);
    expect(
      find.text('Your customer account is ready. Sign in to continue.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRegisterScreen(
  WidgetTester tester,
  _RecordingRepository repository,
  Role role,
) async {
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
            home: RegisterScreen(role: role),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingRepository implements AuthenticationRepository {
  RegisterAccountRequest? submitted;

  @override
  Future<RegisterModel> registerCustomerAccount(RegisterUserParam param) =>
      throw UnimplementedError();

  @override
  Future<RegisterModel> registerDriverAccount(RegisterDriverParam param) =>
      throw UnimplementedError();

  @override
  Future<RegisterAccountResult> registerAccount(
    RegisterAccountRequest request,
  ) async {
    submitted = request;
    return const RegisterAccountResult(
      profileId: 8,
      userName: 'new_customer',
      role: Role.customer,
    );
  }

  @override
  Future<LoginModel> login({required LoginParam param}) =>
      throw UnimplementedError();

  @override
  Future<VehicleTypeModel> getVehicleTypes() => throw UnimplementedError();

  @override
  Future<Role> getRoles() => throw UnimplementedError();
}
