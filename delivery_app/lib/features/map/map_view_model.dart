import 'dart:async';

import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/service/route_service.dart';
import 'package:delivery_app/features/map/service/trip_service.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'map_state.dart';

part 'map_view_model.g.dart';

const String geoapifyApiKey = 'f24b5efe6e764373bf3103d641305d57';

@Riverpod(keepAlive: true)
class MapViewModel extends _$MapViewModel {
  late TripService _tripService;
  late RoutingService _routingService;

  StreamSubscription<Map<String, dynamic>>? _customerSubscription;
  StreamSubscription<Map<String, dynamic>>? _driverSubscription;
  StreamSubscription<LatLng>? _driverLocationSubscription;

  int? _profileId;

  bool _waitingForFirstDriverLocation = false;
  bool _waitingForDestinationRoute = false;

  @override
  MapState build(Role role) {
    _tripService = ref.watch(tripRealtimeServiceProvider);
    _routingService = RoutingService(apiKey: geoapifyApiKey);

    _profileId = ref.watch(appViewModelProvider).profileId;

    ref.onDispose(() {
      _customerSubscription?.cancel();
      _driverSubscription?.cancel();
      _driverLocationSubscription?.cancel();
    });

    return const MapState();
  }

  Future<void> restoreActiveCustomerTrip() async {
    if (_profileId == null) {
      return;
    }
    AppLoading.instance.show();
    try {
      final activeTrip = await _tripService.getTripActive(
        customerId: _profileId!,
      );
      final tripId = activeTrip?.data?.tripId;
      if (tripId == null) {
        return;
      }
      _tripService.setCurrentTripId(tripId);
      _tripService.connectCustomerTracking(tripId);
    } catch (e) {
      debugPrint('------- Restore trip error :$e');
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  void setAddresses({required String pickup, required String destination}) {
    state = state.copyWith(
      pickupAddress: pickup,
      destinationAddress: destination,
      clearError: true,
    );
  }

  Future<void> bookTrip() async {
    if (role != Role.customer) return;

    if (_profileId == null || _profileId! <= 0) {
      _setError('Không tìm thấy Customer ID');
      return;
    }

    if (state.pickupAddress.trim().isEmpty ||
        state.destinationAddress.trim().isEmpty) {
      _setError('Vui lòng nhập điểm đón và điểm đến');
      return;
    }
    AppLoading.instance.show();

    try {
      state = state.copyWith(
        tripStatus: MapTripStatus.booking,
        clearError: true,
      );

      final pickup = await _routingService.geocode(state.pickupAddress);

      final destination = await _routingService.geocode(
        state.destinationAddress,
      );

      final route = await _routingService.getRoute(
        origin: pickup,
        destination: destination,
      );

      final tripId = await _tripService.mapRepository.bookTrip(
        customerId: _profileId!,
        tripDistanceKm: route.distanceKm,
        pickup: pickup,
        destination: destination,
      );

      state = state.copyWith(
        pickup: pickup,
        destination: destination,
        route: route,
        tripId: tripId,
        tripStatus: MapTripStatus.waitingForDriver,
      );

      _connectCustomerTracking(tripId);
    } catch (error) {
      state = state.copyWith(
        tripStatus: MapTripStatus.idle,
        errorMessage: error.toString(),
      );
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  void _connectCustomerTracking(int tripId) {
    _customerSubscription?.cancel();

    _tripService.connectCustomerTracking(tripId);

    _customerSubscription = _tripService.customerTrackingStream.listen(
      _handleCustomerEvent,
    );
  }

  Future<void> _handleCustomerEvent(Map<String, dynamic> message) async {
    final type = message['type'];

    if (type == 'trip_accepted') {
      final driverId = (message['driver_id'] as num).toInt();

      state = state.copyWith(
        driverId: driverId,
        tripStatus: MapTripStatus.driverComing,
      );

      _waitingForFirstDriverLocation = true;
      return;
    }
    AppLoading.instance.show();
    if (type == 'driver_location') {
      final location = LatLng(
        (message['latitude'] as num).toDouble(),
        (message['longitude'] as num).toDouble(),
      );

      state = state.copyWith(driverLocation: location);

      if (_waitingForFirstDriverLocation && state.pickup != null) {
        _waitingForFirstDriverLocation = false;

        await _calculateRoute(origin: location, destination: state.pickup!);
      }

      if (_waitingForDestinationRoute && state.destination != null) {
        _waitingForDestinationRoute = false;

        await _calculateRoute(
          origin: location,
          destination: state.destination!,
        );
      }
      AppLoading.instance.dismiss();
      return;
    }

    if (type == 'trip_started') {
      state = state.copyWith(tripStatus: MapTripStatus.goingToDestination);

      _waitingForDestinationRoute = true;

      if (state.driverLocation != null && state.destination != null) {
        _waitingForDestinationRoute = false;

        await _calculateRoute(
          origin: state.driverLocation!,
          destination: state.destination!,
        );
      }

      return;
    }

    if (type == 'trip_completed') {
      state = state.copyWith(tripStatus: MapTripStatus.completed);

      await _tripService.disconnectCustomerTracking();
      return;
    }

    if (type == 'trip_cancelled') {
      state = state.copyWith(tripStatus: MapTripStatus.cancelled);

      await _tripService.disconnectCustomerTracking();
    }
  }

  Future<void> goOnline() async {
    if (role != Role.driver) return;

    if (_profileId == null || _profileId! <= 0) {
      _setError('Không tìm thấy Driver ID');
      return;
    }
    AppLoading.instance.show();
    try {
      await _driverSubscription?.cancel();

      final stream = _tripService.connectTripNotifications(_profileId!);

      _driverSubscription = stream.listen(
        _handleDriverNotification,
        onError: (error) {
          _setError(error.toString());
        },
      );

      await _tripService.startLocationUpdates(driverId: _profileId!);

      await _driverLocationSubscription?.cancel();

      _driverLocationSubscription = _tripService.driverLocationStream.listen((
        location,
      ) {
        state = state.copyWith(driverLocation: location);
      });
    } catch (error) {
      _setError(error.toString());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  void _handleDriverNotification(Map<String, dynamic> message) {
    final type = message['type'];

    if (type == 'new_trip') {
      final data = Map<String, dynamic>.from(message['data'] as Map);

      final tripId = (data['trip_id'] as num).toInt();

      final trips = [
        ...state.pendingTrips.where(
          (item) => (item['trip_id'] as num).toInt() != tripId,
        ),
        data,
      ];

      state = state.copyWith(pendingTrips: trips);
    }

    if (type == 'trip_taken') {
      final tripId = (message['trip_id'] as num).toInt();

      state = state.copyWith(
        pendingTrips: state.pendingTrips
            .where((item) => (item['trip_id'] as num).toInt() != tripId)
            .toList(),
      );
    }
  }

  Future<void> acceptTrip(int tripId) async {
    AppLoading.instance.show();
    if (role != Role.driver) return;
    if (_profileId == null) return;

    try {
      state = state.copyWith(clearError: true);

      final trip = state.pendingTrips.firstWhere(
        (item) => (item['trip_id'] as num).toInt() == tripId,
      );

      final pickup = LatLng(
        (trip['trip_latitude'] as num).toDouble(),
        (trip['trip_longitude'] as num).toDouble(),
      );

      final destination = LatLng(
        (trip['destination_latitude'] as num).toDouble(),
        (trip['destination_longitude'] as num).toDouble(),
      );

      await _tripService.acceptTrip(driverId: _profileId!, tripId: tripId);

      final driverLocation = await _tripService.getCurrentDriverLocation();

      final route = await _routingService.getRoute(
        origin: driverLocation,
        destination: pickup,
      );

      state = state.copyWith(
        pickup: pickup,
        destination: destination,
        driverLocation: driverLocation,
        route: route,
        tripId: tripId,
        tripStatus: MapTripStatus.driverComing,
        pendingTrips: state.pendingTrips
            .where((item) => (item['trip_id'] as num).toInt() != tripId)
            .toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> startTrip() async {
    if (role != Role.driver) return;
    if (_profileId == null || state.tripId == null) return;

    try {
      AppLoading.instance.show();
      state = state.copyWith(clearError: true);

      await _tripService.startTrip(
        driverId: _profileId!,
        tripId: state.tripId!,
      );

      final driverLocation = await _tripService.getCurrentDriverLocation();

      if (state.destination == null) {
        throw Exception('Không tìm thấy tọa độ điểm đến');
      }

      final route = await _routingService.getRoute(
        origin: driverLocation,
        destination: state.destination!,
      );

      state = state.copyWith(
        driverLocation: driverLocation,
        route: route,
        tripStatus: MapTripStatus.goingToDestination,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> completeTrip() async {
    if (role != Role.driver) return;
    if (_profileId == null || state.tripId == null) return;
    AppLoading.instance.show();
    try {
      await _tripService.completeTrip(
        driverId: _profileId!,
        tripId: state.tripId!,
      );

      state = state.copyWith(tripStatus: MapTripStatus.completed);
    } catch (error) {
      _setError(error.toString());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> cancelTrip() async {
    if (role != Role.customer) return;
    if (_profileId == null || state.tripId == null) return;
    AppLoading.instance.dismiss();
    try {
      await _tripService.mapRepository.cancelCustomerTrip(
        customerId: _profileId!,
        tripId: state.tripId!,
      );

      await _tripService.disconnectCustomerTracking();

      state = state.copyWith(tripStatus: MapTripStatus.cancelled);
    } catch (error) {
      _setError(error.toString());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> _calculateRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final route = await _routingService.getRoute(
        origin: origin,
        destination: destination,
      );

      state = state.copyWith(route: route);
    } catch (error) {
      debugPrint('Calculate route error: $error');
    }
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  Future<void> goOffline() async {
    await _driverSubscription?.cancel();
    await _driverLocationSubscription?.cancel();

    await _tripService.goOffline();

    state = const MapState();
  }
}
