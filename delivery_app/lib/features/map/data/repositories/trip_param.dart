import 'package:delivery_app/data/network/base/param.dart';

class TripParam extends ApiParam {
  final int customerId;

  TripParam(this.customerId);

  @override
  String get path => '/api/user/trips/active';

  @override
  Map<String, dynamic> get queryParameters => {'customer_id': customerId};
}
