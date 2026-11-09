import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

enum LocationAccessFailure { permissionDenied, servicesDisabled, unavailable }

class LocationAccessException implements Exception {
  const LocationAccessException(this.failure);

  final LocationAccessFailure failure;
}

abstract class LocationService {
  Future<bool> requestPermission();

  Future<Coordinates> currentCoordinates();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<Coordinates> currentCoordinates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationAccessException(
          LocationAccessFailure.servicesDisabled,
        );
      }
      if (!await requestPermission()) {
        throw const LocationAccessException(
          LocationAccessFailure.permissionDenied,
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } on LocationAccessException {
      rethrow;
    } catch (_) {
      throw const LocationAccessException(LocationAccessFailure.unavailable);
    }
  }
}
