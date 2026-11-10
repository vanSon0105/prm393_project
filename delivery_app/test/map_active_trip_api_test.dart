import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/exception.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/map/data/repositories/map_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('restores a pending trip from the active-trip API response', () async {
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
                  'data': {
                    'trip_id': 2,
                    'customer_id': 3,
                    'driver_id': null,
                    'trip_status_id': 1,
                    'status_text': 'PENDING',
                    'trip_distance': 5,
                    'trip_price': 50000,
                    'trip_latitude': 21.0323032,
                    'trip_longitude': 105.8506925,
                    'destination_latitude': 21.0211151,
                    'destination_longitude': 105.8221501,
                  },
                },
              ),
            );
          },
        ),
      );

    final trip = await MapRepositoryImpl(ApiProvider(dio))
        .getTripActive(customerId: 3);

    expect(request?.method, 'GET');
    expect(request?.path, contains('/api/user/trips/active'));
    expect(request?.queryParameters['customer_id'], 3);
    expect(trip?.data?.tripId, 2);
    expect(trip?.data?.tripStatusId, 1);
    expect(trip?.data?.destinationLongitude, 105.8221501);
  });

  test('no active trip remains an empty response', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'data': null},
              ),
            );
          },
        ),
      );

    final trip = await MapRepositoryImpl(ApiProvider(dio))
        .getTripActive(customerId: 3);
    expect(trip?.data, isNull);
  });

  test('network errors are not mistaken for an empty trip', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 500),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

    await expectLater(
      MapRepositoryImpl(ApiProvider(dio)).getTripActive(customerId: 3),
      throwsA(isA<ApiException>()),
    );
  });

  test('loads the current driver trip using the driver profile ID', () async {
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
                  'data': {
                    'trip_id': 4,
                    'customer_id': 3,
                    'driver_id': 6,
                    'trip_status_id': 3,
                    'trip_distance': 8,
                    'trip_price': 42000,
                    'trip_latitude': 21.01565,
                    'trip_longitude': 105.50445,
                    'destination_latitude': 21.02322,
                    'destination_longitude': 105.89849,
                  },
                },
              ),
            );
          },
        ),
      );

    final trip = await MapRepositoryImpl(ApiProvider(dio))
        .getActiveDriverTrip(driverId: 6);

    expect(request?.method, 'GET');
    expect(request?.path, contains('/api/driver/trips/active'));
    expect(request?.queryParameters['driver_id'], 6);
    expect(trip?.data?.tripId, 4);
    expect(trip?.data?.tripStatusId, 3);
  });
}
