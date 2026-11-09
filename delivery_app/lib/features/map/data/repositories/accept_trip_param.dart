import 'package:delivery_app/data/network/base/param.dart';

class AcceptTripParam extends ApiParam {
  final int tripId;
  final int driverId;

  @override
  String get path => '/api/driver/trips/$tripId/accept';

  AcceptTripParam({required this.tripId, required this.driverId});

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {'driver_id': driverId};
}
