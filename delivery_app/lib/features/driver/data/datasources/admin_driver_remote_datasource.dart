import '../../../../data/network/base/provider.dart';
import '../models/admin_driver_model.dart';
import 'admin_drivers_param.dart';

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
}
