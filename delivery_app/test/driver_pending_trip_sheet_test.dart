import 'dart:async';

import 'package:delivery_app/features/map/widget/driver_pending_trip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final trip = <String, dynamic>{
    'trip_id': 8,
    'trip_latitude': 21.0132477,
    'trip_longitude': 105.5268992,
    'destination_latitude': 21.0285,
    'destination_longitude': 105.8542,
    'trip_distance': 12,
    'trip_price': 45000,
  };

  Future<void> pumpSheet(
    WidgetTester tester, {
    required Future<String?> Function(LatLng) reverseGeocode,
    required VoidCallback onAccept,
    required ValueNotifier<bool> availability,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        saveLocale: false,
        path: 'resources/langs',
        assetLoader: JsonAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: availability,
                builder: (context, available, _) => DriverPendingTripSheet(
                  trip: trip,
                  available: available,
                  reverseGeocode: reverseGeocode,
                  onAccept: onAccept,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  testWidgets('shows fare before addresses load and accepts after review', (
    tester,
  ) async {
    final pickup = Completer<String?>();
    final destination = Completer<String?>();
    final availability = ValueNotifier(true);
    addTearDown(availability.dispose);
    var accepted = false;
    await pumpSheet(
      tester,
      reverseGeocode: (point) =>
          point.latitude < 21.02 ? pickup.future : destination.future,
      onAccept: () => accepted = true,
      availability: availability,
    );

    expect(find.text('Trip #8'), findsOneWidget);
    expect(find.text('45.000 ₫'), findsOneWidget);
    expect(find.text('12 km'), findsOneWidget);
    expect(find.text('Finding address...'), findsNWidgets(2));

    pickup.complete('Pickup street, Hanoi');
    destination.complete('Destination street, Hanoi');
    await tester.pumpAndSettle();
    expect(find.text('Pickup street, Hanoi'), findsOneWidget);
    expect(find.text('Destination street, Hanoi'), findsOneWidget);

    availability.value = false;
    await tester.pump();
    expect(find.text('This trip is no longer available'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(accepted, isFalse);

    availability.value = true;
    await tester.pump();
    await tester.tap(find.text('Accept'));
    expect(accepted, isTrue);
  });
}
