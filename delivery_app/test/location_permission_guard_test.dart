import 'package:delivery_app/features/location/location_permission_guard.dart';
import 'package:delivery_app/features/location/location_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationService implements LocationService {
  LocationAccessStatus status = LocationAccessStatus.denied;
  LocationAccessStatus requestResult = LocationAccessStatus.denied;
  final List<bool> checks = [];
  int settingsOpens = 0;

  @override
  Future<LocationAccessStatus> checkPermission({
    bool requestIfDenied = false,
  }) async {
    checks.add(requestIfDenied);
    if (requestIfDenied && status == LocationAccessStatus.denied) {
      status = requestResult;
    }
    return status;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpens++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('location gate blocks, opens settings, and rechecks on resume', (
    tester,
  ) async {
    final service = _FakeLocationService();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: JsonAssetLoader(),
        saveLocale: false,
        child: ProviderScope(
          overrides: [locationServiceProvider.overrideWithValue(service)],
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const LocationPermissionGuard(
                child: Scaffold(body: Text('App content')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('App content'), findsNothing);
    expect(find.text('Allow location'), findsOneWidget);
    expect(service.checks, [true]);

    service.requestResult = LocationAccessStatus.deniedForever;
    await tester.tap(find.text('Allow location'));
    await tester.pumpAndSettle();
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('App content'), findsNothing);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(service.settingsOpens, 1);

    service.status = LocationAccessStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('App content'), findsOneWidget);
    expect(service.checks.last, false);

    service.status = LocationAccessStatus.deniedForever;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('App content'), findsNothing);
    expect(find.text('Open settings'), findsOneWidget);
  });
}
