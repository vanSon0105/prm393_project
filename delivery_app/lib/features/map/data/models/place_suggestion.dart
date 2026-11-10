import 'package:latlong2/latlong.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.address, required this.location});

  final String address;
  final LatLng location;

  static PlaceSuggestion? fromJson(Map<String, dynamic> json) {
    final address = json['formatted']?.toString().trim() ?? '';
    final latitude = json['lat'];
    final longitude = json['lon'];
    if (address.isEmpty || latitude is! num || longitude is! num) return null;
    return PlaceSuggestion(
      address: address,
      location: LatLng(latitude.toDouble(), longitude.toDouble()),
    );
  }
}
