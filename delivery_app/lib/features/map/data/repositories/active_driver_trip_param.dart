import 'package:delivery_app/data/network/base/param.dart';

class ActiveDriverTripParam extends ApiParam {
  ActiveDriverTripParam(this.driverId);

  final int driverId;

  @override
  String get path => '/api/driver/trips/active';

  @override
  Map<String, dynamic> get queryParameters => {'driver_id': driverId};
}
