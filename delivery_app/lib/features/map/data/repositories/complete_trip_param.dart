import 'package:delivery_app/features/map/data/repositories/accept_trip_param.dart';

class CompleteTripParam extends AcceptTripParam {
  CompleteTripParam({required super.tripId, required super.driverId});

  @override
  String get path => '/api/driver/trips/$tripId/complete';
}
