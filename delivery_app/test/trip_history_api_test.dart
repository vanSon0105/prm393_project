import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/trip/data/repositories/trip_history_remote_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('requests the signed-in profile and parses a history page', () async {
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
                  'profile_id': 7,
                  'role': 'CUSTOMER',
                  'data': [
                    {
                      'trip_id': 31,
                      'trip_status_id': 4,
                      'customer_name': 'Customer A',
                      'driver_name': 'Driver B',
                      'trip_distance': 8,
                      'trip_price': 42000.0,
                      'trip_latitude': 21.03,
                      'trip_longitude': 105.85,
                      'destination_latitude': 21.04,
                      'destination_longitude': 105.86,
                    },
                  ],
                  'has_more': true,
                },
              ),
            );
          },
        ),
      );

    final page = await TripHistoryRemoteRepository(ApiProvider(dio))
        .getHistory(profileId: 7, limit: 20, offset: 40);

    expect(request?.method, 'GET');
    expect(request?.path, endsWith('/api/trips/history'));
    expect(request?.queryParameters, {
      'profile_id': 7,
      'limit': 20,
      'offset': 40,
    });
    expect(page.hasMore, isTrue);
    expect(page.entries.single.tripId, 31);
    expect(page.entries.single.driverName, 'Driver B');
  });

  test('handles a cancelled trip without a driver or price', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'trip_id': 32,
                      'trip_status_id': 5,
                      'customer_name': 'Customer A',
                      'driver_name': null,
                      'trip_distance': null,
                      'trip_price': null,
                      'trip_latitude': 21.03,
                      'trip_longitude': 105.85,
                      'destination_latitude': 21.04,
                      'destination_longitude': 105.86,
                    },
                  ],
                  'has_more': false,
                },
              ),
            );
          },
        ),
      );

    final entry = (await TripHistoryRemoteRepository(
      ApiProvider(dio),
    ).getHistory(profileId: 7)).entries.single;
    expect(entry.isCompleted, isFalse);
    expect(entry.driverName, isNull);
    expect(entry.price, isNull);
  });
}
