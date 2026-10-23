import 'dart:convert';

import 'package:delivery_app/features/driver_rating/driver_rating_screen.dart';
import 'package:delivery_app/features/payment/trip_payment_screen.dart';
import 'package:delivery_app/features/profile/edit_profile_screen.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _translations = <Locale, Map<String, dynamic>>{};

class _TestTranslations extends AssetLoader {
  const _TestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      _translations[locale]!;
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
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
      assetLoader: const _TestTranslations(),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: screen,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final locale in [const Locale('en', 'US'), const Locale('ko', 'KR')]) {
      final data = await rootBundle.loadString(
        'resources/langs/${locale.languageCode}-${locale.countryCode}.json',
      );
      _translations[locale] = Map<String, dynamic>.from(jsonDecode(data) as Map);
    }
  });

  test('New screens have named routes', () {
    expect(appRouter.namedLocation(AppRoute.driverRating.rawValue), '/driver-rating');
    expect(appRouter.namedLocation(AppRoute.tripPayment.rawValue), '/trip-payment');
    expect(appRouter.namedLocation(AppRoute.editProfile.rawValue), '/edit-profile');
  });

  testWidgets('Rating tags translate and can be selected', (tester) async {
    await pumpScreen(tester, const DriverRatingScreen());
    expect(find.text('Rate the driver'), findsOneWidget);
    final tag = find.widgetWithText(FilterChip, 'Safe driving');
    await tester.ensureVisible(tag);
    await tester.tap(tag);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(tag).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Payment method switches to QR', (tester) async {
    await pumpScreen(tester, const TripPaymentScreen());
    await tester.tap(find.text('Bank QR'));
    await tester.pumpAndSettle();
    expect(find.text('QR illustration — not available for payment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile can enter edit mode', (tester) async {
    await pumpScreen(tester, const EditProfileScreen());
    final edit = find.text('Edit profile');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('Save profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
