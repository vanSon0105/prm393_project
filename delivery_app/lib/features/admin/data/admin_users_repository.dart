import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/admin/domain/entities/app_user.dart';

class AdminUsersRepository {
  const AdminUsersRepository(this._api);

  final ApiProvider _api;

  Future<List<AppUser>> getUsers() async {
    final response = await _api.requestApi(param: _AdminUsersParam());
    if (response is! List) {
      throw const FormatException('Invalid admin users response');
    }
    return response
        .map((item) => AppUser.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }
}

class _AdminUsersParam extends ApiParam {
  @override
  String get path => '/api/admin/users';
}
