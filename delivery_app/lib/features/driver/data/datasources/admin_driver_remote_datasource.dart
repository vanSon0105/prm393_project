import '../../../../data/network/base/provider.dart';
import '../models/admin_driver_model.dart';
import '../models/admin_driver_request_model.dart';
import 'admin_drivers_param.dart';
import 'admin_driver_requests_param.dart';

class AdminDriverRemoteDataSource {
  const AdminDriverRemoteDataSource(this._apiProvider);

  final ApiProvider _apiProvider;

  Future<List<AdminDriverModel>> fetchDrivers() async {
    final response = await _apiProvider.requestApi(param: AdminDriversParam());
    if (response is! List) {
      throw const FormatException('Invalid driver list response');
    }
    return response
        .map(
          (item) =>
              AdminDriverModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<AdminDriverRequestModel>> fetchRequests() async {
    final response = await _apiProvider.requestApi(
      param: AdminDriverRequestsParam(),
    );
    if (response == null) return const [];
    if (response is! List) {
      throw const FormatException('Invalid driver requests response');
    }
    return response
        .map(
          (item) => AdminDriverRequestModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> reviewRequest({
    required int driverId,
    required bool approved,
    String reason = '',
  }) async {
    if (!approved && reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'A rejection reason is required',
      );
    }
    await _apiProvider.requestApi(
      param: ReviewDriverRequestParam(
        driverId: driverId,
        approved: approved,
        reason: reason,
      ),
    );
  }
}
