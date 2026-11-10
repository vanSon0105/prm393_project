import 'package:delivery_app/data/network/base/param.dart';

class CancelDriverTripParam extends ApiParam {
  CancelDriverTripParam({required this.tripId, required this.driverId});

  final int tripId;
  final int driverId;

  @override
  String get path => '/api/driver/trips/$tripId/cancel';

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {'driver_id': driverId};
}
