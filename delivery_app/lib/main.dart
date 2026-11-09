import 'package:delivery_app/routes/app_router.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/location/location_service.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await ref.read(locationServiceProvider).requestPermission();
      } catch (error) {
        debugPrint('Location permission request failed: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Bloc',
      debugShowCheckedModeBanner: true,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
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
        return FlutterEasyLoading(child: child);
      },
    );
  }
}

Future<void> initService() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppLoading.instance.configLoading();
}
