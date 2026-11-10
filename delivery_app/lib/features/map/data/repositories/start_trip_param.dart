import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/features/map/data/repositories/accept_trip_param.dart';

class StartTripParam extends AcceptTripParam {
  StartTripParam({required super.tripId, required super.driverId});

  @override
  String get path => '/api/driver/trips/$tripId/start';

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {'driver_id': driverId};
}
