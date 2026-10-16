import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/environment.dart';
import 'data/local/sharepreference/share_preference_repository.dart';
import 'di/repository_module.dart';
import 'main.dart';

void main() async {
  Environment.configFlavor(FlavorValue.prod);
  await initService();
  final prefs = await SharedPreferences.getInstance();
  SharePreferenceRepository sharePreferencesUtils = SharePreferenceRepository(
    prefs,
  );
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('ko', 'KR')],
      fallbackLocale: Locale('en', 'US'),
      path: 'resources/langs',
      assetLoader: JsonAssetLoader(),
      child: ProviderScope(
        overrides: [
          appSharePreferencesProvider.overrideWithValue(sharePreferencesUtils),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
