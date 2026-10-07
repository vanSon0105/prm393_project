import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';

import 'config/environment.dart';
import 'main.dart';

void main() async {
  Environment.configFlavor(FlavorValue.prod);
  await initService();
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('ko', 'KR')],
      fallbackLocale: Locale('en', 'US'),
      path: 'resources/langs',
      assetLoader: JsonAssetLoader(),
      child: const MyApp(),
    ),
  );
}
