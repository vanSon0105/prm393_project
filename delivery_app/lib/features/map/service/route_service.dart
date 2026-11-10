import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/network/base/interceptor.dart';
import '../data/models/route_result.dart';

class RoutingService {
  RoutingService({required this.apiKey})
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      )..interceptors.add(CustomInterceptor());

  final String apiKey;
  final Dio _dio;

  Future<LatLng> geocode(String address) async {
    await Future.delayed(const Duration(seconds: 3));
    final response = await _dio.get(
      'https://api.geoapify.com/v1/geocode/search',
      queryParameters: {
        'text': address,
        'format': 'json',
        'limit': 1,
        'lang': 'vi',
        'filter': 'countrycode:vn',
        'apiKey': apiKey,
      },
    );

    final results = response.data['results'] as List<dynamic>;

    if (results.isEmpty) {
      throw Exception('Không tìm thấy địa chỉ: $address');
    }

    final result = Map<String, dynamic>.from(results.first as Map);

    return LatLng(
      (result['lat'] as num).toDouble(),
      (result['lon'] as num).toDouble(),
    );
  }

  Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final response = await _dio.get(
      'https://api.geoapify.com/v1/routing',
      queryParameters: {
        'waypoints':
            '${origin.latitude},${origin.longitude}|'
            '${destination.latitude},${destination.longitude}',
        'mode': 'drive',
        'type': 'short',
        'format': 'geojson',
        'units': 'metric',
        'apiKey': apiKey,
      },
    );

    return RouteResult.fromGeoJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
