import 'package:delivery_app/data/network/base/param.dart';
import 'package:latlong2/latlong.dart';

class BookParam extends ApiParam {
  final int customerId;
  final int tripDistanceKm;
  final LatLng pickup;
  final LatLng destination;

  @override
  String get path => '/api/user/trips/book';

  BookParam({
    required this.customerId,
    required this.tripDistanceKm,
    required this.pickup,
    required this.destination,
  });

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {
    'customer_id': customerId,
    'trip_distance': tripDistanceKm,
    'trip_latitude': pickup.latitude,
    'trip_longitude': pickup.longitude,
    'destination_latitude': destination.latitude,
    'destination_longitude': destination.longitude,
  };
}
