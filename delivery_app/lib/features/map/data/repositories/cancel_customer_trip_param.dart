import 'package:delivery_app/data/network/base/param.dart';

class CancelCustomerTripParam extends ApiParam {
  CancelCustomerTripParam({required this.tripId, required this.customerId});

  final int tripId;
  final int customerId;

  @override
  String get path => '/api/user/trips/$tripId/cancel';

  @override
  String get method => Method.post;

  @override
  Map<String, dynamic> get bodyParams => {'customer_id': customerId};
}
