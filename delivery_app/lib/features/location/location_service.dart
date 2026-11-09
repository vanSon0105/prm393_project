import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

abstract class LocationService {
  Future<LocationAccessStatus> checkPermission({bool requestIfDenied = false});

  Future<bool> openAppSettings();
}

enum LocationAccessStatus { granted, denied, deniedForever }

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationAccessStatus> checkPermission({
    bool requestIfDenied = false,
  }) async {
    var permission = await Geolocator.checkPermission();
    if (requestIfDenied &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine)) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationAccessStatus.granted,
      LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
      _ => LocationAccessStatus.denied,
    };
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
