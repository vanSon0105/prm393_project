import '../../../../data/network/base/param.dart';

class AdminDriverRequestsParam extends ApiParam {
  @override
  String get path => '/api/admin/drivers/requests';
}

class ReviewDriverRequestParam extends ApiParam {
  ReviewDriverRequestParam({
    required this.driverId,
    required this.approved,
    this.reason = '',
  });

  final int driverId;
  final bool approved;
  final String reason;

  @override
  String get method => Method.post;

  @override
  String get path => '/api/admin/drivers/$driverId/approve';

  @override
  Map<String, dynamic> get bodyParams => {
    'driver_id': driverId,
    'status': approved,
    if (!approved) 'reason': reason.trim(),
  };
}
