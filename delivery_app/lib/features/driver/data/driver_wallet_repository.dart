import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';

class DriverWalletRepository {
  const DriverWalletRepository(this._api);

  final ApiProvider _api;

  Future<int> getBalance(int driverId) async {
    final response = await _api.requestApi(param: _DriverWalletParam(driverId));
    if (response is! Map || response['data'] is! Map) {
      throw const FormatException('Invalid driver wallet response');
    }
    final balance = (response['data'] as Map)['balance'];
    if (balance is! num) {
      throw const FormatException('Invalid driver wallet balance');
    }
    return balance.toInt();
  }
}

class _DriverWalletParam extends ApiParam {
  _DriverWalletParam(this.driverId);

  final int driverId;

  @override
  String get path => '/api/driver/$driverId/wallet';
}
