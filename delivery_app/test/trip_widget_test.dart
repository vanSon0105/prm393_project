import 'dart:convert';

import 'package:delivery_app/features/detail_delivery/detail_delivery_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _translations = <Locale, Map<String, dynamic>>{};

class _TestTranslations extends AssetLoader {
  const _TestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      _translations[locale]!;
}

Future<void> start(WidgetTester tester, {double width = 390}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      startLocale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      path: 'resources/langs',
      assetLoader: const _TestTranslations(),
      child: Builder(
        builder: (context) => ProviderScope(
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const DetailDeliveryPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> pressInList(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> role(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Choose role'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
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
  testWidgets('Cancellation requires confirmation and updates history', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Track trip'));
    await tester.pumpAndSettle();
    await pressInList(tester, 'Cancel trip');
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel trip'), findsOneWidget);
    await tester.tap(find.text('Cancel trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel trip'));
    await tester.pumpAndSettle();
    expect(find.text('Trip history'), findsOneWidget);
    expect(find.text('Track trip'), findsNothing);
    await tester.tap(find.text('In progress'));
    await tester.pumpAndSettle();
    expect(find.text('No matching trips'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Driver completion updates customer history before rating', (
    tester,
  ) async {
    await start(tester);
    await role(tester, 'Driver');
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    await pressInList(tester, 'Confirm pickup');
    expect(find.text('Complete trip'), findsOneWidget);
    await pressInList(tester, 'Complete trip');
    await tester.tap(find.text('Delivered and paid'));
    await tester.pumpAndSettle();
    await role(tester, 'Customer');
    expect(find.text('Track trip'), findsNothing);
    await tester.tap(find.text('Current trip'));
    await tester.pumpAndSettle();
    await pressInList(tester, 'Rate driver');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit rating'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();
    expect(find.text('You rated 5 stars'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completed filter opens the correct historical trip', (
    tester,
  ) async {
    await start(tester);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18 Lê Lợi, Quận 1'));
    await tester.pumpAndSettle();
    expect(find.text('Trip NS2310'), findsOneWidget);
    expect(find.text('Phạm Quốc Huy'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to history'));
    await tester.pumpAndSettle();
    expect(find.text('Completed trips'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Three screens support narrow displays and larger text', (
    tester,
  ) async {
    await start(tester, width: 320);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await pressInList(tester, 'Track trip');
    expect(find.text('Trip NS2408'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await role(tester, 'Driver');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
