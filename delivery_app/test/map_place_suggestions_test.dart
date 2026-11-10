import 'package:delivery_app/features/map/service/route_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('reverse geocodes restored trip coordinates', () async {
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
                  'results': [
                    {'formatted': 'Hoan Kiem, Ha Noi, Viet Nam'},
                  ],
                },
              ),
            );
          },
        ),
      );

    final address = await RoutingService(
      apiKey: 'test-key',
      dio: dio,
    ).reverseGeocode(const LatLng(21.0285, 105.8542));

    expect(request?.path, 'https://api.geoapify.com/v1/geocode/reverse');
    expect(request?.queryParameters['lat'], 21.0285);
    expect(request?.queryParameters['lon'], 105.8542);
    expect(address, 'Hoan Kiem, Ha Noi, Viet Nam');
  });

  test(
    'place suggestions are restricted to Hanoi and include coordinates',
    () async {
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
                    'results': [
                      {
                        'formatted': 'Hồ Hoàn Kiếm, Hà Nội, Việt Nam',
                        'lat': 21.0285,
                        'lon': 105.8542,
                      },
                      {'formatted': '', 'lat': 21.0, 'lon': 105.8},
                    ],
                  },
                ),
              );
            },
          ),
        );

      final service = RoutingService(apiKey: 'test-key', dio: dio);
      final results = await service.suggestPlaces('Hoàn Kiếm');

      expect(request?.path, 'https://api.geoapify.com/v1/geocode/autocomplete');
      expect(request?.queryParameters['text'], 'Hoàn Kiếm');
      expect(
        request?.queryParameters['filter'],
        'rect:105.29,20.55,106.03,21.43',
      );
      expect(request?.queryParameters['limit'], 5);
      expect(results, hasLength(1));
      expect(results.single.address, 'Hồ Hoàn Kiếm, Hà Nội, Việt Nam');
      expect(results.single.location.latitude, 21.0285);
      expect(results.single.location.longitude, 105.8542);
    },
  );

  test('short text does not send a request', () async {
    var requested = false;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requested = true;
            handler.next(options);
          },
        ),
      );
    final results = await RoutingService(
      apiKey: 'test-key',
      dio: dio,
    ).suggestPlaces('H');
    expect(results, isEmpty);
    expect(requested, isFalse);
  });
}
