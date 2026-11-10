import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapLocationException implements Exception {
  const MapLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final currentMapLocationProvider = Provider<Future<LatLng> Function()>((ref) {
  return () async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw MapLocationException(LocaleKeys.map_location_service_disabled.tr());
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw MapLocationException(
        LocaleKeys.map_location_permission_denied.tr(),
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  };
});
