import 'dart:convert';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/exception.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/map/data/repositories/map_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test(
    'customer cancellation sends the customer ID to the trip endpoint',
    () async {
      RequestOptions? request;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response(requestOptions: options, statusCode: 200),
              );
            },
          ),
        );

      await MapRepositoryImpl(ApiProvider(dio))
          .cancelCustomerTrip(customerId: 7, tripId: 42);

      expect(request?.method, 'POST');
      expect(request?.path, endsWith('/api/user/trips/42/cancel'));
      expect(jsonDecode(request!.data as String), {'customer_id': 7});
    },
  );

  test(
    'driver cancellation sends the driver ID to the trip endpoint',
    () async {
      RequestOptions? request;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response(requestOptions: options, statusCode: 200),
              );
            },
          ),
        );

      await MapRepositoryImpl(ApiProvider(dio))
          .cancelDriverTrip(driverId: 9, tripId: 42);

      expect(request?.method, 'POST');
      expect(request?.path, endsWith('/api/driver/trips/42/cancel'));
      expect(jsonDecode(request!.data as String), {'driver_id': 9});
    },
  );

  test('cancellation rejection is surfaced to the caller', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {'error': 'Trip cannot be cancelled'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

    await expectLater(
      MapRepositoryImpl(ApiProvider(dio))
          .cancelDriverTrip(driverId: 9, tripId: 42),
      throwsA(
        isA<ApiException>().having((error) => error.httpCode, 'status', 409),
      ),
    );
  });
}
