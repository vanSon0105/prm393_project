import 'dart:async';
import 'dart:convert';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/features/map/data/repositories/map_repository_impl.dart';
import 'package:delivery_app/features/map/domain/repositories/map_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../data/network/base/provider.dart';
import '../data/models/trip_model.dart';

part 'trip_service.g.dart';

const double maxPickupDistanceKm = 5.0;

@Riverpod(keepAlive: true)
TripService tripRealtimeService(Ref ref) {
  final service = TripService(
    apiBaseUrl: Environment.baseUrl,
    wsBaseUrl: Environment.baseUrl.replaceFirst('http', 'ws'),
    mapRepository: MapRepositoryImpl(ref.watch(apiProviderProvider)),
  );

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
}

class TripService {
  TripService({
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.mapRepository,
  });

  final String apiBaseUrl;
  final String wsBaseUrl;
  final MapRepository mapRepository;

  WebSocketChannel? _notificationChannel;
  WebSocketChannel? _locationChannel;
  WebSocketChannel? _customerTrackingChannel;

  Timer? _locationTimer;

  int _driverId = 0;
  int _currentTripId = 0;
  bool _sendingLocation = false;

  final Map<int, Map<String, dynamic>> _pendingTrips = {};
  final Set<int> _reportedNearbyTrips = {};

  final StreamController<Map<String, dynamic>> _customerTrackingController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<LatLng> _driverLocationController =
      StreamController<LatLng>.broadcast();

  Stream<Map<String, dynamic>> get customerTrackingStream =>
      _customerTrackingController.stream;

  Stream<LatLng> get driverLocationStream => _driverLocationController.stream;

  Map<int, Map<String, dynamic>> get pendingTrips =>
      Map.unmodifiable(_pendingTrips);

  Future<TripModel?> getTripActive({required int customerId}) async {
    return await mapRepository.getTripActive(customerId: customerId);
  }

  Stream<Map<String, dynamic>> connectTripNotifications(int driverId) {
    _driverId = driverId;

    _notificationChannel?.sink.close();

    _notificationChannel = WebSocketChannel.connect(
      Uri.parse('$wsBaseUrl/ws/driver/trips?driver_id=$driverId'),
    );

    return _notificationChannel!.stream.map((event) {
      final message = Map<String, dynamic>.from(
        jsonDecode(event.toString()) as Map,
      );

      _handleDriverNotification(message);

      return message;
    });
  }

  void _handleDriverNotification(Map<String, dynamic> message) {
    final type = message['type'];

    if (type == 'new_trip') {
      final data = Map<String, dynamic>.from(message['data'] as Map);

      final tripId = (data['trip_id'] as num).toInt();

      _pendingTrips[tripId] = data;
    } else if (type == 'trip_taken') {
      final tripId = (message['trip_id'] as num).toInt();

      _pendingTrips.remove(tripId);
      _reportedNearbyTrips.remove(tripId);
    }
  }

  Future<void> startLocationUpdates({required int driverId}) async {
    _driverId = driverId;

    await _ensureLocationPermission();

    await _locationChannel?.sink.close();

    _locationChannel = WebSocketChannel.connect(
      Uri.parse('$wsBaseUrl/ws/driver/location?driver_id=$driverId'),
    );

    await _sendCurrentLocation();

    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendCurrentLocation(),
    );
  }

  Future<LatLng> getCurrentDriverLocation() async {
    await _ensureLocationPermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<void> acceptTrip({required int driverId, required int tripId}) async {
    final trip = _pendingTrips[tripId];

    if (trip == null) {
      throw Exception('Chuyến này không còn trong danh sách chuyến chờ');
    }

    final pickup = LatLng(
      (trip['trip_latitude'] as num).toDouble(),
      (trip['trip_longitude'] as num).toDouble(),
    );

    final position = await getCurrentDriverLocation();

    final distanceKm =
        Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          pickup.latitude,
          pickup.longitude,
        ) /
        1000;

    if (distanceKm > maxPickupDistanceKm) {
      throw Exception('Bạn đang ở ngoài bán kính 5km của điểm đón');
    }

    await mapRepository.acceptTrip(driverId: driverId, tripId: tripId);

    _currentTripId = tripId;

    _pendingTrips.remove(tripId);
    _reportedNearbyTrips.remove(tripId);

    await _sendCurrentLocation();
  }

  Future<void> startTrip({required int driverId, required int tripId}) async {
    await mapRepository.startTrip(driverId: driverId, tripId: tripId);

    _currentTripId = tripId;

    await _sendCurrentLocation();
  }

  Future<void> completeTrip({
    required int driverId,
    required int tripId,
  }) async {
    await mapRepository.completeTrip(driverId: driverId, tripId: tripId);

    _currentTripId = 0;
  }

  void setCurrentTripId(int? tripId) {
    _currentTripId = tripId ?? 0;
  }

  void connectCustomerTracking(int tripId) {
    disconnectCustomerTracking();

    _customerTrackingChannel = WebSocketChannel.connect(
      Uri.parse('$wsBaseUrl/ws/user/track/$tripId'),
    );

    _customerTrackingChannel!.stream.listen(
      (event) {
        try {
          final message = Map<String, dynamic>.from(
            jsonDecode(event.toString()) as Map,
          );

          _customerTrackingController.add(message);
        } catch (error) {
          debugPrint('Customer tracking parse error: $error');
        }
      },
      onError: (error) {
        debugPrint('Customer tracking socket error: $error');
      },
      onDone: () {
        debugPrint('Customer tracking socket disconnected');
      },
    );
  }

  Future<void> disconnectCustomerTracking() async {
    await _customerTrackingChannel?.sink.close();
    _customerTrackingChannel = null;
  }

  Future<void> _sendCurrentLocation() async {
    if (_sendingLocation || _locationChannel == null || _driverId <= 0) {
      return;
    }

    _sendingLocation = true;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);

      _driverLocationController.add(currentLocation);

      if (_currentTripId > 0) {
        _locationChannel?.sink.add(
          jsonEncode({
            'trip_id': _currentTripId,
            'latitude': position.latitude,
            'longitude': position.longitude,
          }),
        );
      }

      for (final entry in _pendingTrips.entries.toList()) {
        final tripId = entry.key;
        final trip = entry.value;

        final pickupLatitude = (trip['trip_latitude'] as num).toDouble();
        final pickupLongitude = (trip['trip_longitude'] as num).toDouble();

        final distanceKm =
            Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              pickupLatitude,
              pickupLongitude,
            ) /
            1000;

        if (distanceKm <= maxPickupDistanceKm) {
          if (_reportedNearbyTrips.add(tripId)) {
            _notificationChannel?.sink.add(
              jsonEncode({
                'type': 'driver_nearby',
                'trip_id': tripId,
                'latitude': position.latitude,
                'longitude': position.longitude,
              }),
            );
          }
        } else if (_reportedNearbyTrips.remove(tripId)) {
          _notificationChannel?.sink.add(
            jsonEncode({
              'type': 'driver_out_of_range',
              'trip_id': tripId,
              'latitude': position.latitude,
              'longitude': position.longitude,
            }),
          );
        }
      }
    } catch (error) {
      debugPrint('Không thể lấy/gửi GPS Driver: $error');
    } finally {
      _sendingLocation = false;
    }
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Vui lòng bật dịch vụ định vị trên điện thoại');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Ứng dụng chưa được cấp quyền truy cập vị trí');
    }
  }

  Future<void> goOffline() async {
    _locationTimer?.cancel();
    _locationTimer = null;

    _pendingTrips.clear();
    _reportedNearbyTrips.clear();

    _currentTripId = 0;

    await _notificationChannel?.sink.close();
    await _locationChannel?.sink.close();
    await _customerTrackingChannel?.sink.close();

    _notificationChannel = null;
    _locationChannel = null;
    _customerTrackingChannel = null;
  }

  Future<void> dispose() async {
    await goOffline();

    await _customerTrackingController.close();
    await _driverLocationController.close();
  }
}
