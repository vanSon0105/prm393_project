import 'dart:convert';

import 'package:delivery_app/features/setting/setting_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('all supported languages provide the same translation keys', () async {
    Future<Map<String, dynamic>> load(String locale) async =>
        jsonDecode(await rootBundle.loadString('resources/langs/$locale.json'))
            as Map<String, dynamic>;

    final english = await load('en-US');
    for (final locale in ['ko-KR', 'vi-VN', 'ja-JP']) {
      final translated = await load(locale);
      expect(translated.keys.toSet(), english.keys.toSet());
      for (final key in english.keys) {
        final placeholders = RegExp(r'\{[^{}]+\}');
        Set<String> variables(String text) => placeholders
            .allMatches(text)
            .map((match) => match.group(0)!)
            .toSet();
        expect(
          variables(translated[key] as String),
          variables(english[key] as String),
          reason: '$locale: $key',
        );
      }
    }
  });

  testWidgets('Settings switches to Vietnamese and Japanese', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ko', 'KR'),
          Locale('vi', 'VN'),
          Locale('ja', 'JP'),
        ],
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        saveLocale: false,
        path: 'resources/langs',
        assetLoader: JsonAssetLoader(),
        child: Builder(
          builder: (context) => ProviderScope(
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const SettingPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vietnamese').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Nhật').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsOneWidget);
  });
}
