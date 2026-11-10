import 'dart:convert';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/driver_rating/data/trip_rating_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('submits a trip vote and comment to the review API', () async {
    RequestOptions? request;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {'trip_id': 31, 'message': 'Saved'},
                },
              ),
            );
          },
        ),
      );

    await TripRatingRepository(ApiProvider(dio))
        .submit(tripId: 31, vote: 4, comment: 'Friendly driver');

    expect(request?.method, 'POST');
    expect(request?.path, endsWith('/api/user/drivers/review'));
    expect(jsonDecode(request!.data as String), {
      'trip_id': 31,
      'vote': 4,
      'comment': 'Friendly driver',
    });
  });

  test('rejects an invalid trip ID or vote before sending', () async {
    final repository = TripRatingRepository(ApiProvider(Dio()));
    await expectLater(
      repository.submit(tripId: 0, vote: 5, comment: ''),
      throwsArgumentError,
    );
    await expectLater(
      repository.submit(tripId: 31, vote: 6, comment: ''),
      throwsArgumentError,
    );
  });

  test('recognizes an already rated trip from the API error', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 400,
                data: {'error': 'Chuyến đi này đã được đánh giá trước đó'},
              ),
            ),
          ),
        ),
      );

    await expectLater(
      TripRatingRepository(ApiProvider(dio))
          .submit(tripId: 7, vote: 5, comment: ''),
      throwsA(isA<TripAlreadyRatedException>()),
    );
  });
}
