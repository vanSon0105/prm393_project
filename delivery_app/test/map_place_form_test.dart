import 'dart:convert';
import 'dart:async';

import 'package:delivery_app/features/app_state.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/data/models/place_suggestion.dart';
import 'package:delivery_app/features/map/map_page.dart';
import 'package:delivery_app/features/map/map_state.dart';
import 'package:delivery_app/features/map/map_view_model.dart';
import 'package:delivery_app/features/map/service/trip_service.dart';
import 'package:delivery_app/features/map/service/current_map_location_provider.dart';
import 'package:delivery_app/features/map/domain/repositories/map_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic>? _translations;

class _TestTranslations extends AssetLoader {
  const _TestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      _translations!;
}

class _UnusedRepository implements MapRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestTripService extends TripService {
  _TestTripService()
    : super(apiBaseUrl: '', wsBaseUrl: '', mapRepository: _UnusedRepository());
}

class _TestMapViewModel extends MapViewModel {
  LatLng? bookedPickup;
  LatLng? bookedDestination;

  @override
  MapState build(Role role) {
    super.build(role);
    return const MapState();
  }

  @override
  Future<void> restoreActiveCustomerTrip() async {}

  @override
  Future<List<PlaceSuggestion>> suggestPlaces(String query) async => [
    const PlaceSuggestion(
      address: 'Hồ Hoàn Kiếm, Hà Nội, Việt Nam',
      location: LatLng(21.0285, 105.8542),
    ),
  ];

  @override
  Future<String?> reverseGeocode(LatLng location) async => 'Current place';

  @override
  Future<void> bookTrip({
    LatLng? pickupLocation,
    LatLng? destinationLocation,
  }) async {
    if (state.pickupAddress.isEmpty || state.destinationAddress.isEmpty) {
      return super.bookTrip(
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
      );
    }
    bookedPickup = pickupLocation;
    bookedDestination = destinationLocation;
  }
}

class _RestoredMapViewModel extends _TestMapViewModel {
  @override
  Future<void> restoreActiveCustomerTrip() async {
    state = state.copyWith(
      tripId: 7,
      tripStatus: MapTripStatus.waitingForDriver,
      pickup: const LatLng(21.0285, 105.8542),
      destination: const LatLng(21.0211, 105.8221),
      pickupAddress: 'Hoan Kiem, Ha Noi',
      destinationAddress: 'Ba Dinh, Ha Noi',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    _translations = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('resources/langs/en-US.json'))
          as Map,
    );
  });

  testWidgets('restored trip fills pickup and destination fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        appViewModelProvider.overrideWithValue(
          AppState(role: Role.customer, profileId: 7),
        ),
        tripRealtimeServiceProvider.overrideWithValue(_TestTripService()),
        mapViewModelProvider.overrideWith(_RestoredMapViewModel.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        startLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: const _TestTranslations(),
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const MapPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, 'Hoan Kiem, Ha Noi');
    expect(fields[1].controller?.text, 'Ba Dinh, Ha Noi');
    expect(find.text('Finding a driver...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing shows a place and clears the booking warning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        appViewModelProvider.overrideWithValue(
          AppState(role: Role.customer, profileId: 7),
        ),
        tripRealtimeServiceProvider.overrideWithValue(_TestTripService()),
        mapViewModelProvider.overrideWith(_TestMapViewModel.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        startLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: const _TestTranslations(),
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const MapPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Book trip'));
    await tester.pump();
    expect(
      find.text('Enter both pickup and destination addresses'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(
      find.text('Enter both pickup and destination addresses'),
      findsNothing,
    );

    await tester.tap(find.text('Book trip'));
    await tester.pump();
    expect(
      find.text('Enter both pickup and destination addresses'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, 'Hoan Kiem');
    await tester.pump();
    expect(
      find.text('Enter both pickup and destination addresses'),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Hồ Hoàn Kiếm, Hà Nội, Việt Nam'), findsOneWidget);

    await tester.tap(find.text('Hồ Hoàn Kiếm, Hà Nội, Việt Nam'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Hồ Hoàn Kiếm, Hà Nội, Việt Nam',
    );
    await tester.enterText(find.byType(TextField).last, 'Hoan Kiem');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.text('Hồ Hoàn Kiếm, Hà Nội, Việt Nam').last);
    await tester.pump();
    await tester.tap(find.text('Book trip'));
    final viewModel = container.read(
      mapViewModelProvider(Role.customer).notifier,
    ) as _TestMapViewModel;
    expect(viewModel.bookedPickup, const LatLng(21.0285, 105.8542));
    expect(viewModel.bookedDestination, const LatLng(21.0285, 105.8542));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pickup can use GPS then switch back to manual entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        appViewModelProvider.overrideWithValue(
          AppState(role: Role.customer, profileId: 7),
        ),
        tripRealtimeServiceProvider.overrideWithValue(_TestTripService()),
        currentMapLocationProvider.overrideWithValue(
          () async => const LatLng(21.03, 105.85),
        ),
        mapViewModelProvider.overrideWith(_TestMapViewModel.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        startLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: const _TestTranslations(),
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const MapPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Use my location'));
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Current place',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      false,
    );

    await tester.enterText(find.byType(TextField).last, 'Hanoi Opera House');
    await tester.tap(find.text('Book trip'));
    final viewModel = container.read(
      mapViewModelProvider(Role.customer).notifier,
    ) as _TestMapViewModel;
    expect(viewModel.bookedPickup, const LatLng(21.03, 105.85));

    await tester.tap(find.text('Enter pickup'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      true,
    );
    await tester.enterText(find.byType(TextField).first, 'Hoan Kiem');
    await tester.tap(find.text('Book trip'));
    expect(viewModel.bookedPickup, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GPS failure restores manual pickup and enables booking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = Completer<LatLng>();
    final container = ProviderContainer(
      overrides: [
        appViewModelProvider.overrideWithValue(
          AppState(role: Role.customer, profileId: 7),
        ),
        tripRealtimeServiceProvider.overrideWithValue(_TestTripService()),
        currentMapLocationProvider.overrideWithValue(() => location.future),
        mapViewModelProvider.overrideWith(_TestMapViewModel.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        startLocale: const Locale('en', 'US'),
        path: 'resources/langs',
        assetLoader: const _TestTranslations(),
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const MapPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Manual pickup');
    await tester.tap(find.text('Use my location'));
    await tester.pump();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Book trip'),
          )
          .onPressed,
      isNull,
    );

    location.completeError(const MapLocationException('Location unavailable'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Location unavailable'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Manual pickup',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      true,
    );
    expect(tester.takeException(), isNull);
  });
}
