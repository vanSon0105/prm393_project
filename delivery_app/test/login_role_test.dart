import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/login/login_page.dart';
import 'package:delivery_app/features/auth/login/login_view_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingLoginViewModel extends LoginViewModel {
  Role? submittedRole;

  @override
  Future<void> login({
    required String userName,
    required String password,
    required Role role,
  }) async {
    submittedRole = role;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Login submits the role currently selected on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final viewModel = _RecordingLoginViewModel();
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
            overrides: [loginViewModelProvider.overrideWith(() => viewModel)],
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const LoginPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'driver');
    await tester.enterText(find.byType(TextField).last, 'qwer1212!');
    await tester.tap(find.text('Sign in'));

    expect(viewModel.submittedRole, Role.driver);
    expect(tester.takeException(), isNull);
  });
}
