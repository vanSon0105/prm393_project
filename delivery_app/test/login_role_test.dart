import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/login/login_page.dart';
import 'package:delivery_app/features/auth/login/login_view_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingLoginViewModel extends LoginViewModel {
  String? submittedUserName;
  String? submittedPassword;

  @override
  Future<void> login({
    required String userName,
    required String password,
  }) async {
    submittedUserName = userName;
    submittedPassword = password;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Login submits credentials without asking for a role', (
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
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    expect(find.text('Choose a role to continue.'), findsNothing);
    expect(find.text('Driver'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'driver');
    await tester.enterText(find.byType(TextField).last, 'qwer1212!');
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      'qwer1212!',
    );
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.text('Sign in'));

    expect(viewModel.submittedUserName, 'driver');
    expect(viewModel.submittedPassword, 'qwer1212!');
    await tester.tap(find.textContaining('Register', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Create an account as'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Login request contains only username and password', () {
    final request = LoginParam(userName: 'driver', password: 'secret123');
    expect(request.bodyParams, {
      'user_name': 'driver',
      'password': 'secret123',
    });
  });
}
