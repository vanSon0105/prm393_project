import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/data/network/base/exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripRatingRepositoryProvider = Provider<TripRatingRepository>(
  (ref) => TripRatingRepository(ref.watch(apiProviderProvider)),
);

class TripAlreadyRatedException implements Exception {
  const TripAlreadyRatedException();
}

class TripRatingRepository {
  const TripRatingRepository(this._api);

  final ApiProvider _api;

  Future<void> submit({
    required int tripId,
    required int vote,
    required String comment,
  }) async {
    if (tripId <= 0) throw ArgumentError.value(tripId, 'tripId');
    if (vote < 1 || vote > 5) throw ArgumentError.value(vote, 'vote');
    try {
      await _api.requestApi(
        param: _SubmitTripRatingParam(
          tripId: tripId,
          vote: vote,
          comment: comment,
        ),
      );
    } on ApiException catch (error) {
      if (error.httpCode == 409 ||
          (error.httpCode == 400 &&
              error.message?.contains('đã được đánh giá') == true)) {
        throw const TripAlreadyRatedException();
      }
      rethrow;
    }
  }
}

class _SubmitTripRatingParam extends ApiParam {
  _SubmitTripRatingParam({
    required this.tripId,
    required this.vote,
    required this.comment,
  });

  final int tripId;
  final int vote;
  final String comment;

  @override
  String get method => Method.post;

  @override
  String get path => '/api/user/drivers/review';

  @override
  Map<String, dynamic> get bodyParams => {
    'trip_id': tripId,
    'vote': vote,
    'comment': comment,
  };
}
