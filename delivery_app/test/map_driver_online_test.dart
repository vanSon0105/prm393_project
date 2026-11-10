import 'dart:async';

import 'package:delivery_app/features/app_state.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/domain/repositories/map_repository.dart';
import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:delivery_app/features/map/map_state.dart';
import 'package:delivery_app/features/map/map_view_model.dart';
import 'package:delivery_app/features/map/service/trip_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _UnusedRepository implements MapRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DriverTripService extends TripService {
  _DriverTripService()
    : super(apiBaseUrl: '', wsBaseUrl: '', mapRepository: _UnusedRepository());

  final locationStarted = Completer<void>();
  final notifications = StreamController<Map<String, dynamic>>.broadcast();
  int connections = 0;
  int disconnections = 0;
  TripModel? activeTrip;
  int? trackedTripId;

  @override
  Future<TripModel?> getActiveDriverTrip({required int driverId}) async =>
      activeTrip;

  @override
  void setCurrentTripId(int? tripId) => trackedTripId = tripId;

  @override
  Stream<Map<String, dynamic>> connectTripNotifications(int driverId) {
    connections++;
    return notifications.stream;
  }

  @override
  Future<void> waitForDriverNotifications() async {}

  @override
  Stream<LatLng> get driverLocationStream => const Stream.empty();

  @override
  Future<void> startLocationUpdates({required int driverId}) =>
      locationStarted.future;

  @override
  Future<void> goOffline() async {
    disconnections++;
    if (!notifications.isClosed) await notifications.close();
  }
}

void main() {
  test(
    'driver online status follows connection and prevents duplicate taps',
    () async {
      final service = _DriverTripService();
      final container = ProviderContainer(
        overrides: [
          appViewModelProvider.overrideWithValue(
            AppState(role: Role.driver, profileId: 6),
          ),
          tripRealtimeServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final provider = mapViewModelProvider(Role.driver);
      final notifier = container.read(provider.notifier);
      final connecting = notifier.goOnline();

      expect(
        container.read(provider).driverOnlineStatus,
        DriverOnlineStatus.connecting,
      );
      await Future<void>.delayed(Duration.zero);
      await notifier.goOnline();
      expect(service.connections, 1);

      service.locationStarted.complete();
      await connecting;
      expect(
        container.read(provider).driverOnlineStatus,
        DriverOnlineStatus.online,
      );

      await notifier.goOffline();
      expect(
        container.read(provider).driverOnlineStatus,
        DriverOnlineStatus.offline,
      );
      expect(service.disconnections, 1);
    },
  );

  test('driver becomes offline if the trip socket disconnects', () async {
    final service = _DriverTripService();
    final container = ProviderContainer(
      overrides: [
        appViewModelProvider.overrideWithValue(
          AppState(role: Role.driver, profileId: 6),
        ),
        tripRealtimeServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final provider = mapViewModelProvider(Role.driver);
    final connecting = container.read(provider.notifier).goOnline();
    service.locationStarted.complete();
    await connecting;
    expect(
      container.read(provider).driverOnlineStatus,
      DriverOnlineStatus.online,
    );

    await service.notifications.close();
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(provider).driverOnlineStatus,
      DriverOnlineStatus.offline,
    );
    expect(container.read(provider).errorMessage, isNotNull);
  });

  test('driver returns offline when initial location times out', () async {
    final service = _DriverTripService();
    final container = ProviderContainer(
      overrides: [
        appViewModelProvider.overrideWithValue(
          AppState(role: Role.driver, profileId: 6),
        ),
        tripRealtimeServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final provider = mapViewModelProvider(Role.driver);
    final connecting = container.read(provider.notifier).goOnline();
    await Future<void>.delayed(Duration.zero);
    service.locationStarted.completeError(TimeoutException('GPS timeout'));
    await connecting;

    expect(
      container.read(provider).driverOnlineStatus,
      DriverOnlineStatus.offline,
    );
    expect(container.read(provider).errorMessage, isNotNull);
    expect(service.disconnections, 1);
  });

  for (final tripStatusId in [2, 3]) {
    testWidgets('restores driver trip in status $tripStatusId after login', (
      tester,
    ) async {
      EasyLoading.instance.maskColor = Colors.black54;
      final service = _DriverTripService()
        ..activeTrip = TripModel(
          data: TripData(
            tripId: 4,
            customerId: 3,
            driverId: 6,
            tripStatusId: tripStatusId,
            tripLatitude: 21.01565,
            tripLongitude: 105.50445,
            destinationLatitude: 21.02322,
            destinationLongitude: 105.89849,
          ),
        );
      final container = ProviderContainer(
        overrides: [
          appViewModelProvider.overrideWithValue(
            AppState(role: Role.driver, profileId: 6),
          ),
          tripRealtimeServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: EasyLoading.init(),
            home: const Scaffold(),
          ),
        ),
      );

      final provider = mapViewModelProvider(Role.driver);
      await container.read(provider.notifier).restoreActiveDriverTrip();
      final state = container.read(provider);
      expect(state.tripId, 4);
      expect(
        state.tripStatus,
        tripStatusId == 3
            ? MapTripStatus.goingToDestination
            : MapTripStatus.driverComing,
      );
      expect(state.destination?.longitude, 105.89849);
      expect(service.trackedTripId, 4);
      await tester.pump();
      expect(service.connections, 1);

      service.locationStarted.complete();
      await tester.pump();
    });
  }
}
