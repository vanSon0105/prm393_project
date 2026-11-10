import 'dart:async';

import 'package:delivery_app/data/network/base/exception.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/map/data/models/place_suggestion.dart';
import 'package:delivery_app/features/map/data/models/price_model.dart';
import 'package:delivery_app/features/map/service/route_service.dart';
import 'package:delivery_app/features/map/service/trip_service.dart';
import 'package:delivery_app/features/trip/presentation/providers/trip_history_provider.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'map_state.dart';

part 'map_view_model.g.dart';

const String geoapifyApiKey = 'f24b5efe6e764373bf3103d641305d57';

class _DriverConnectionLostException implements Exception {}

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
  bool _isCancellingTrip = false;
  bool _driverConnectionLostDuringConnect = false;

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
    final customerId = _profileId;
    if (customerId == null) {
      return;
    }
    AppLoading.instance.show();
    try {
      final activeTrip = await _tripService.getTripActive(
        customerId: customerId,
      );
      if (!ref.mounted || _profileId != customerId) return;
      final trip = activeTrip?.data;
      final tripId = trip?.tripId;
      if (tripId == null) {
        return;
      }
      final pickup = trip?.tripLatitude != null && trip?.tripLongitude != null
          ? LatLng(trip!.tripLatitude!, trip.tripLongitude!)
          : null;
      final destination =
          trip?.destinationLatitude != null &&
              trip?.destinationLongitude != null
          ? LatLng(trip!.destinationLatitude!, trip.destinationLongitude!)
          : null;
      final pickupFallback = _coordinateLabel(pickup);
      final destinationFallback = _coordinateLabel(destination);
      state = state.copyWith(
        pickupAddress: pickupFallback,
        destinationAddress: destinationFallback,
        pickup: pickup,
        destination: destination,
        tripId: tripId,
        driverId: trip?.driverId,
        tripStatus: switch (trip?.tripStatusId) {
          2 => MapTripStatus.driverComing,
          3 => MapTripStatus.goingToDestination,
          _ => MapTripStatus.waitingForDriver,
        },
      );
      _waitingForFirstDriverLocation = trip?.tripStatusId == 2;
      _waitingForDestinationRoute = trip?.tripStatusId == 3;
      _tripService.setCurrentTripId(tripId);
      _connectCustomerTracking(tripId);
      unawaited(
        _restoreTripAddresses(
          customerId: customerId,
          tripId: tripId,
          pickup: pickup,
          destination: destination,
          pickupFallback: pickupFallback,
          destinationFallback: destinationFallback,
        ),
      );
    } catch (e) {
      debugPrint('------- Restore trip error :$e');
      _setError(LocaleKeys.map_restore_trip_failed.tr());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> restoreActiveDriverTrip() async {
    if (role != Role.driver) return;
    final driverId = _profileId;
    if (driverId == null || driverId <= 0) return;

    AppLoading.instance.show();
    try {
      final activeTrip = await _tripService.getActiveDriverTrip(
        driverId: driverId,
      );
      if (!ref.mounted || _profileId != driverId) return;
      final trip = activeTrip?.data;
      if (trip?.tripId == null ||
          trip?.tripLatitude == null ||
          trip?.tripLongitude == null ||
          trip?.destinationLatitude == null ||
          trip?.destinationLongitude == null) {
        return;
      }
      if (trip!.tripStatusId != 2 && trip.tripStatusId != 3) return;

      final pickup = LatLng(trip.tripLatitude!, trip.tripLongitude!);
      final destination = LatLng(
        trip.destinationLatitude!,
        trip.destinationLongitude!,
      );
      final tripId = trip.tripId!;
      state = state.copyWith(
        pickup: pickup,
        destination: destination,
        tripId: tripId,
        tripStatus: trip.tripStatusId == 3
            ? MapTripStatus.goingToDestination
            : MapTripStatus.driverComing,
        clearError: true,
      );
      _tripService.setCurrentTripId(tripId);
      unawaited(
        _resumeActiveDriverTrip(
          driverId: driverId,
          tripId: tripId,
          target: trip.tripStatusId == 3 ? destination : pickup,
        ),
      );
    } catch (error) {
      debugPrint('Restore driver trip error: $error');
      if (ref.mounted) _setError(LocaleKeys.map_restore_trip_failed.tr());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> _resumeActiveDriverTrip({
    required int driverId,
    required int tripId,
    required LatLng target,
  }) async {
    await goOnline();
    if (!ref.mounted || _profileId != driverId || state.tripId != tripId) {
      return;
    }
    final origin = state.driverLocation;
    if (origin == null) return;
    try {
      final route = await _routingService.getRoute(
        origin: origin,
        destination: target,
      );
      if (ref.mounted && _profileId == driverId && state.tripId == tripId) {
        state = state.copyWith(route: route);
      }
    } catch (error) {
      debugPrint('Restore driver route error: $error');
    }
  }

  String _coordinateLabel(LatLng? point) => point == null
      ? ''
      : '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

  Future<void> _restoreTripAddresses({
    required int customerId,
    required int tripId,
    required LatLng? pickup,
    required LatLng? destination,
    required String pickupFallback,
    required String destinationFallback,
  }) async {
    final addresses = await Future.wait([
      _resolveAddress(pickup, pickupFallback),
      _resolveAddress(destination, destinationFallback),
    ]);
    if (!ref.mounted || _profileId != customerId || state.tripId != tripId) {
      return;
    }
    state = state.copyWith(
      pickupAddress: state.pickupAddress == pickupFallback
          ? addresses[0]
          : state.pickupAddress,
      destinationAddress: state.destinationAddress == destinationFallback
          ? addresses[1]
          : state.destinationAddress,
    );
  }

  Future<String> _resolveAddress(LatLng? point, String fallback) async {
    if (point == null) return fallback;
    try {
      return await _routingService.reverseGeocode(point) ?? fallback;
    } catch (error) {
      debugPrint('Could not reverse geocode trip location: $error');
      return fallback;
    }
  }

  void setAddresses({required String pickup, required String destination}) {
    state = state.copyWith(
      pickupAddress: pickup,
      destinationAddress: destination,
      clearError: true,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<List<PlaceSuggestion>> suggestPlaces(String query) =>
      _routingService.suggestPlaces(query);

  Future<String?> reverseGeocode(LatLng location) =>
      _routingService.reverseGeocode(location);

  void showLocationError(String message) => _setError(message);

  Future<void> bookTrip({
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    bool book = true,
  }) async {
    if (role != Role.customer) return;

    if (_profileId == null || _profileId! <= 0) {
      _setError(LocaleKeys.map_customer_id_missing.tr());
      return;
    }

    if (state.pickupAddress.trim().isEmpty ||
        state.destinationAddress.trim().isEmpty) {
      _setError(LocaleKeys.map_addresses_required.tr());
      return;
    }
    AppLoading.instance.show();

    try {
      state = state.copyWith(
        tripStatus: MapTripStatus.booking,
        clearError: true,
      );

      final pickup =
          pickupLocation ?? await _routingService.geocode(state.pickupAddress);

      final destination =
          destinationLocation ??
          await _routingService.geocode(state.destinationAddress);

      final route = await _routingService.getRoute(
        origin: pickup,
        destination: destination,
      );
      final priceModel = await _tripService.mapRepository.getPriceConfig();
      final tripDistance = route.distanceKm;
      final tripPrice = PriceModel.calculatePrice(
        tripDistance,
        priceModel.data ?? [],
      );
      if (!book) {
        state = state.copyWith(
          tripDistance: tripDistance,
          tripPrice: tripPrice,
          tripStatus: MapTripStatus.idle,
        );
      } else {
        final tripId = await _tripService.mapRepository.bookTrip(
          customerId: _profileId!,
          tripDistanceKm: tripDistance.toInt(),
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
      }
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
      if (state.tripStatus == MapTripStatus.goingToDestination ||
          state.tripStatus == MapTripStatus.completed ||
          state.tripStatus == MapTripStatus.cancelled) {
        return;
      }
      final driverId = (message['driver_id'] as num).toInt();

      state = state.copyWith(
        driverId: driverId,
        tripStatus: MapTripStatus.driverComing,
      );

      _waitingForFirstDriverLocation = true;
      return;
    }
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
      if (_profileId != null) ref.invalidate(tripHistoryProvider(_profileId!));

      await _tripService.disconnectCustomerTracking();
      return;
    }

    if (type == 'driver_cancelled_trip') {
      _waitingForFirstDriverLocation = false;
      _waitingForDestinationRoute = false;
      state = MapState(
        pickupAddress: state.pickupAddress,
        destinationAddress: state.destinationAddress,
        pickup: state.pickup,
        destination: state.destination,
        tripId: state.tripId,
        tripStatus: MapTripStatus.waitingForDriver,
      );
      return;
    }

    if (type == 'trip_cancelled' || type == 'trip_cancelled_by_customer') {
      if (_profileId != null) ref.invalidate(tripHistoryProvider(_profileId!));
      _tripService.setCurrentTripId(null);
      state = MapState(
        pickupAddress: state.pickupAddress,
        destinationAddress: state.destinationAddress,
        tripStatus: MapTripStatus.cancelled,
      );
      await _tripService.disconnectCustomerTracking();
    }
  }

  Future<void> goOnline() async {
    if (role != Role.driver) return;
    if (state.driverOnlineStatus != DriverOnlineStatus.offline) return;

    if (_profileId == null || _profileId! <= 0) {
      _setError(LocaleKeys.map_driver_id_missing.tr());
      return;
    }
    state = state.copyWith(
      driverOnlineStatus: DriverOnlineStatus.connecting,
      clearError: true,
    );
    _driverConnectionLostDuringConnect = false;
    try {
      await _driverSubscription?.cancel();

      final stream = _tripService.connectTripNotifications(_profileId!);

      _driverSubscription = stream.listen(
        _handleDriverNotification,
        onError: (error) {
          _handleDriverConnectionLost();
        },
        onDone: _handleDriverConnectionLost,
      );

      await _tripService.waitForDriverNotifications();
      await _driverLocationSubscription?.cancel();

      _driverLocationSubscription = _tripService.driverLocationStream.listen((
        location,
      ) {
        state = state.copyWith(driverLocation: location);
      });
      await _tripService.startLocationUpdates(driverId: _profileId!);
      if (_driverConnectionLostDuringConnect) {
        throw _DriverConnectionLostException();
      }
      if (ref.mounted) {
        state = state.copyWith(driverOnlineStatus: DriverOnlineStatus.online);
      }
    } catch (error) {
      await _driverSubscription?.cancel();
      _driverSubscription = null;
      await _driverLocationSubscription?.cancel();
      _driverLocationSubscription = null;
      await _tripService.goOffline();
      if (ref.mounted) {
        state = state.copyWith(
          driverOnlineStatus: DriverOnlineStatus.offline,
          errorMessage: error is TimeoutException
              ? LocaleKeys.map_online_timeout.tr()
              : error is _DriverConnectionLostException
              ? LocaleKeys.map_online_connection_lost.tr()
              : error.toString(),
        );
      }
    }
  }

  void _handleDriverConnectionLost() {
    if (!ref.mounted) return;
    if (state.driverOnlineStatus == DriverOnlineStatus.connecting) {
      _driverConnectionLostDuringConnect = true;
      return;
    }
    if (state.driverOnlineStatus != DriverOnlineStatus.online) {
      return;
    }
    state = state.copyWith(
      driverOnlineStatus: DriverOnlineStatus.offline,
      errorMessage: LocaleKeys.map_online_connection_lost.tr(),
    );
    final locationSubscription = _driverLocationSubscription;
    if (locationSubscription != null) {
      unawaited(locationSubscription.cancel());
    }
    _driverLocationSubscription = null;
    unawaited(_tripService.goOffline());
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

    if (type == 'trip_cancelled_by_customer' &&
        (message['trip_id'] as num?)?.toInt() == state.tripId) {
      state = MapState(
        driverLocation: state.driverLocation,
        pendingTrips: state.pendingTrips,
        driverOnlineStatus: state.driverOnlineStatus,
      );
    }
  }

  Future<void> acceptTrip(int tripId) async {
    if (role != Role.driver) return;
    if (_profileId == null) return;
    AppLoading.instance.show();

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

      state = state.copyWith(
        pickup: pickup,
        destination: destination,
        tripId: tripId,
        tripStatus: MapTripStatus.driverComing,
        pendingTrips: state.pendingTrips
            .where((item) => (item['trip_id'] as num).toInt() != tripId)
            .toList(),
      );

      final driverLocation = await _tripService.getCurrentDriverLocation();

      final route = await _routingService.getRoute(
        origin: driverLocation,
        destination: pickup,
      );

      if (state.tripId != tripId) return;

      state = state.copyWith(
        pickup: pickup,
        destination: destination,
        driverLocation: driverLocation,
        route: route,
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
        throw Exception(LocaleKeys.map_destination_coordinates_missing.tr());
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
      ref.invalidate(tripHistoryProvider(_profileId!));
    } catch (error) {
      _setError(error.toString());
    } finally {
      AppLoading.instance.dismiss();
    }
  }

  Future<void> cancelTrip() async {
    if (_isCancellingTrip || _profileId == null || state.tripId == null) return;
    if (role == Role.customer &&
        state.tripStatus != MapTripStatus.waitingForDriver &&
        state.tripStatus != MapTripStatus.driverComing) {
      return;
    }
    if (role == Role.driver && state.tripStatus != MapTripStatus.driverComing) {
      return;
    }
    if (role != Role.customer && role != Role.driver) return;

    _isCancellingTrip = true;
    try {
      AppLoading.instance.show();
      state = state.copyWith(clearError: true);
      final tripId = state.tripId!;
      if (role == Role.customer) {
        await _tripService.cancelCustomerTrip(
          customerId: _profileId!,
          tripId: tripId,
        );
        await _tripService.disconnectCustomerTracking();
        ref.invalidate(tripHistoryProvider(_profileId!));
        state = MapState(
          pickupAddress: state.pickupAddress,
          destinationAddress: state.destinationAddress,
          tripStatus: MapTripStatus.cancelled,
        );
      } else {
        await _tripService.cancelDriverTrip(
          driverId: _profileId!,
          tripId: tripId,
        );
        state = MapState(
          driverLocation: state.driverLocation,
          pendingTrips: state.pendingTrips,
          driverOnlineStatus: state.driverOnlineStatus,
        );
      }
    } on ApiException catch (error) {
      _setError(
        error.httpCode == 409
            ? LocaleKeys.map_cancel_unavailable.tr()
            : LocaleKeys.map_cancel_failed.tr(),
      );
    } catch (error) {
      _setError(error.toString());
    } finally {
      _isCancellingTrip = false;
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
    if (state.driverOnlineStatus != DriverOnlineStatus.online) return;
    state = state.copyWith(
      driverOnlineStatus: DriverOnlineStatus.disconnecting,
    );
    await _driverSubscription?.cancel();
    await _driverLocationSubscription?.cancel();

    await _tripService.goOffline();

    if (ref.mounted) {
      state = state.copyWith(
        driverOnlineStatus: DriverOnlineStatus.offline,
        pendingTrips: const [],
        clearError: true,
      );
    }
  }
}
