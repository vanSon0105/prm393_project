import 'package:delivery_app/routes/app_router.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/environment.dart';

final _adminPreviewRouter = createAppRouter(
  initialLocation: AppRoute.admin.rawValue,
);

Future<void> main() async {
  Environment.configFlavor(FlavorValue.dev);
  await initService();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'resources/langs',
      assetLoader: JsonAssetLoader(),
      child: const MyApp(showAdminPreview: true),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.showAdminPreview = false});

  final bool showAdminPreview;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Flutter Bloc',
        debugShowCheckedModeBanner: !showAdminPreview,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        themeMode: ThemeMode.light,
        routerConfig: showAdminPreview ? _adminPreviewRouter : appRouter,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          splashColor: Colors.white,
          highlightColor: Colors.white,
          primaryColor: Colors.white,
          colorScheme: const ColorScheme.light(primary: Colors.black),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          dividerTheme: const DividerThemeData(
            color: Colors.grey,
            thickness: 1,
            space: 1,
          ),
          appBarTheme: const AppBarTheme(color: Colors.white),
          useMaterial3: true,
        ),
        builder: (context, child) {
          if (showAdminPreview) return child ?? const SizedBox.shrink();
          return FlutterEasyLoading(child: child);
        },
      ),
    );
  }
}

Future<void> initService() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppLoading.instance.configLoading();
}
