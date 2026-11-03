import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';

import '../domain/entities/admin_finance.dart';
import '../domain/repositories/admin_finance_repository.dart';

class AdminFinanceRemoteRepository implements AdminFinanceRepository {
  const AdminFinanceRemoteRepository(this._api);

  final ApiProvider _api;

  @override
  Future<AdminBankAccount?> getBankAccount() async {
    final response = await _api.requestApi(
      param: _FinanceParam('/api/admin/bank-account'),
    );
    final data = _data(response);
    if (data == null) return null;
    if (data is! Map) {
      throw const FormatException('Invalid bank account response');
    }
    return AdminBankAccount.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> updateBankAccount(AdminBankAccount account) => _api.requestApi(
    param: _FinanceParam(
      '/api/admin/bank-account',
      method: Method.put,
      body: account.toJson(),
    ),
  );

  @override
  Future<List<DriverTopUpRequest>> getTopUpRequests() async {
    final response = await _api.requestApi(
      param: _FinanceParam(
        '/api/admin/top-up-requests',
        query: {'status': 'pending'},
      ),
    );
    final data = _data(response);
    if (data is! List) {
      throw const FormatException('Invalid top-up requests response');
    }
    return data
        .map(
          (item) => DriverTopUpRequest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> reviewTopUpRequest({
    required int requestId,
    required bool approved,
    String reason = '',
  }) {
    if (!approved && reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'A rejection reason is required',
      );
    }
    final action = approved ? 'approve' : 'reject';
    return _api.requestApi(
      param: _FinanceParam(
        '/api/admin/top-up-requests/$requestId/$action',
        method: Method.post,
        body: approved ? {} : {'reason': reason.trim()},
      ),
    );
  }

  dynamic _data(dynamic response) {
    if (response is! Map || !response.containsKey('data')) {
      throw const FormatException('Invalid admin finance response');
    }
    return response['data'];
  }
}

class _FinanceParam extends ApiParam {
  _FinanceParam(
    this.path, {
    this.method = Method.get,
    this.body = const {},
    this.query = const {},
  });

  @override
  final String path;
  @override
  final String method;
  final Map<String, dynamic> body;
  final Map<String, dynamic> query;

  @override
  Map<String, dynamic> get bodyParams => {...body};

  @override
  Map<String, dynamic> get queryParameters => {...query};
}
