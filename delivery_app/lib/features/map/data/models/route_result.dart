import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  int get distanceKm => (distanceMeters / 1000).ceil();

  factory RouteResult.fromGeoJson(Map<String, dynamic> json) {
    final features = json['features'] as List<dynamic>;

    if (features.isEmpty) {
      throw Exception(LocaleKeys.map_route_not_found.tr());
    }

    final feature = Map<String, dynamic>.from(features.first as Map);
    final properties = Map<String, dynamic>.from(feature['properties'] as Map);
    final geometry = Map<String, dynamic>.from(feature['geometry'] as Map);

    final rawCoordinates = geometry['coordinates'] as List<dynamic>;

    final List<dynamic> coordinates;

    if (rawCoordinates.isNotEmpty &&
        rawCoordinates.first is List &&
        (rawCoordinates.first as List).isNotEmpty &&
        (rawCoordinates.first as List).first is num) {
      coordinates = rawCoordinates;
    } else {
      coordinates = rawCoordinates
          .expand((element) => element as List<dynamic>)
          .toList();
    }

    final points = coordinates.map((item) {
      final coordinate = item as List<dynamic>;

      return LatLng(
        (coordinate[1] as num).toDouble(),
        (coordinate[0] as num).toDouble(),
      );
    }).toList();

    return RouteResult(
      points: points,
      distanceMeters: (properties['distance'] as num).toDouble(),
      durationSeconds: (properties['time'] as num).toDouble(),
    );
  }
}
