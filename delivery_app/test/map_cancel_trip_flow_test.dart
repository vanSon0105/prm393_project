import 'package:delivery_app/features/app_state.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/data/network/base/exception.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/domain/repositories/map_repository.dart';
import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:delivery_app/features/map/map_state.dart';
import 'package:delivery_app/features/map/map_view_model.dart';
import 'package:delivery_app/features/map/service/trip_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedRepository implements MapRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTripService extends TripService {
  _RecordingTripService()
    : super(apiBaseUrl: '', wsBaseUrl: '', mapRepository: _UnusedRepository());

  int? cancelledCustomerId;
  int? cancelledDriverId;
  int? cancelledTripId;
  bool trackingDisconnected = false;
  bool rejectDriverCancellation = false;
  TripModel? activeTrip;
  int? trackedTripId;

  @override
  Future<TripModel?> getTripActive({required int customerId}) async =>
      activeTrip;

  @override
  void connectCustomerTracking(int tripId) {
    trackedTripId = tripId;
  }

  @override
  Stream<Map<String, dynamic>> get customerTrackingStream =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<void> cancelCustomerTrip({
    required int customerId,
    required int tripId,
  }) async {
    cancelledCustomerId = customerId;
    cancelledTripId = tripId;
  }

  @override
  Future<void> cancelDriverTrip({
    required int driverId,
    required int tripId,
  }) async {
    if (rejectDriverCancellation) {
      throw ApiException(
        url: '/api/driver/trips/$tripId/cancel',
        httpCode: 409,
      );
    }
    cancelledDriverId = driverId;
    cancelledTripId = tripId;
  }

  @override
  Future<void> disconnectCustomerTracking() async {
    trackingDisconnected = true;
  }
}

class _ActiveTripViewModel extends MapViewModel {
  @override
  MapState build(Role role) {
    super.build(role);
    return const MapState(tripId: 42, tripStatus: MapTripStatus.driverComing);
  }
}

Future<ProviderContainer> _start(
  WidgetTester tester,
  Role role,
  _RecordingTripService service, {
  MapViewModel Function()? createViewModel,
}) async {
  EasyLoading.instance.maskColor = Colors.black54;
  final container = ProviderContainer(
    overrides: [
      appViewModelProvider.overrideWithValue(
        AppState(role: role, profileId: 7),
      ),
      tripRealtimeServiceProvider.overrideWithValue(service),
      mapViewModelProvider.overrideWith(
        createViewModel ?? _ActiveTripViewModel.new,
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(builder: EasyLoading.init(), home: const Scaffold()),
    ),
  );
  return container;
}

void main() {
  testWidgets('customer cancellation clears the active trip and tracking', (
    tester,
  ) async {
    final service = _RecordingTripService();
    final container = await _start(tester, Role.customer, service);
    final provider = mapViewModelProvider(Role.customer);

    await container.read(provider.notifier).cancelTrip();

    expect(container.read(provider).errorMessage, isNull);
    expect(service.cancelledCustomerId, 7);
    expect(service.cancelledTripId, 42);
    expect(service.trackingDisconnected, isTrue);
    expect(container.read(provider).tripId, isNull);
    expect(container.read(provider).tripStatus, MapTripStatus.cancelled);
  });

  testWidgets('restored customer trip can be cancelled after reopening', (
    tester,
  ) async {
    final service = _RecordingTripService()
      ..activeTrip = TripModel(
        data: TripData(
          tripId: 55,
          tripStatusId: 2,
          driverId: 9,
        ),
      );
    final container = await _start(
      tester,
      Role.customer,
      service,
      createViewModel: MapViewModel.new,
    );
    final provider = mapViewModelProvider(Role.customer);

    await container.read(provider.notifier).restoreActiveCustomerTrip();
    expect(container.read(provider).tripId, 55);
    expect(container.read(provider).driverId, 9);
    expect(container.read(provider).tripStatus, MapTripStatus.driverComing);
    expect(service.trackedTripId, 55);

    await container.read(provider.notifier).cancelTrip();
    expect(service.cancelledTripId, 55);
    expect(container.read(provider).tripId, isNull);
  });

  testWidgets('driver cancellation returns to the available-trip state', (
    tester,
  ) async {
    final service = _RecordingTripService();
    final container = await _start(tester, Role.driver, service);
    final provider = mapViewModelProvider(Role.driver);

    await container.read(provider.notifier).cancelTrip();

    expect(container.read(provider).errorMessage, isNull);
    expect(service.cancelledDriverId, 7);
    expect(service.cancelledTripId, 42);
    expect(container.read(provider).tripId, isNull);
    expect(container.read(provider).tripStatus, MapTripStatus.idle);
  });

  testWidgets('a rejected driver cancellation keeps the active trip', (
    tester,
  ) async {
    final service = _RecordingTripService()..rejectDriverCancellation = true;
    final container = await _start(tester, Role.driver, service);
    final provider = mapViewModelProvider(Role.driver);

    await container.read(provider.notifier).cancelTrip();

    expect(container.read(provider).tripId, 42);
    expect(container.read(provider).tripStatus, MapTripStatus.driverComing);
    expect(container.read(provider).errorMessage, isNotNull);
  });
}
