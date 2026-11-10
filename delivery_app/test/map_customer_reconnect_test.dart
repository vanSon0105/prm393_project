import 'dart:async';

import 'package:delivery_app/features/app_state.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:delivery_app/features/map/domain/repositories/map_repository.dart';
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

class _CustomerTripService extends TripService {
  _CustomerTripService()
    : super(apiBaseUrl: '', wsBaseUrl: '', mapRepository: _UnusedRepository());

  final events = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<TripModel?> getTripActive({required int customerId}) async =>
      TripModel(
        data: TripData(
          tripId: 4,
          customerId: customerId,
          driverId: 6,
          tripStatusId: 3,
        ),
      );

  @override
  void connectCustomerTracking(int tripId) {}

  @override
  Stream<Map<String, dynamic>> get customerTrackingStream => events.stream;
}

void main() {
  testWidgets(
    'old accepted event cannot reopen cancellation for a going trip',
    (tester) async {
      EasyLoading.instance.maskColor = Colors.black54;
      final service = _CustomerTripService();
      addTearDown(service.events.close);
      final container = ProviderContainer(
        overrides: [
          appViewModelProvider.overrideWithValue(
            AppState(role: Role.customer, profileId: 3),
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

      final provider = mapViewModelProvider(Role.customer);
      await container.read(provider.notifier).restoreActiveCustomerTrip();
      expect(
        container.read(provider).tripStatus,
        MapTripStatus.goingToDestination,
      );

      service.events.add({
        'type': 'trip_accepted',
        'trip_id': 4,
        'driver_id': 6,
      });
      await tester.pump();

      expect(
        container.read(provider).tripStatus,
        MapTripStatus.goingToDestination,
      );
      expect(container.read(provider).tripId, 4);
    },
  );
}
