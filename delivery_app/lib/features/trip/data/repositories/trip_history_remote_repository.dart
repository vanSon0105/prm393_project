import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';

import '../models/trip_history_model.dart';

class TripHistoryRemoteRepository {
  const TripHistoryRemoteRepository(this._api);

  final ApiProvider _api;

  Future<TripHistoryPageData> getHistory({
    required int profileId,
    int limit = 20,
    int offset = 0,
  }) async {
    if (profileId <= 0) throw ArgumentError.value(profileId, 'profileId');
    final response = await _api.requestApi(
      param: _TripHistoryParam(profileId, limit, offset),
    );
    return TripHistoryPageData.fromJson(response);
  }
}

class _TripHistoryParam extends ApiParam {
  _TripHistoryParam(this.profileId, this.limit, this.offset);

  final int profileId;
  final int limit;
  final int offset;

  @override
  String get path => '/api/trips/history';

  @override
  Map<String, dynamic> get queryParameters => {
    'profile_id': profileId,
    'limit': limit,
    'offset': offset,
  };
}
