import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/network/base/interceptor.dart';
import '../data/models/place_suggestion.dart';
import '../data/models/route_result.dart';

class RoutingService {
  RoutingService({required this.apiKey, Dio? dio})
    : _dio =
          dio ??
          (Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          )..interceptors.add(CustomInterceptor()));

  final String apiKey;
  final Dio _dio;

  Future<List<PlaceSuggestion>> suggestPlaces(String query) async {
    if (query.trim().length < 3) return const [];
    final response = await _dio.get(
      'https://api.geoapify.com/v1/geocode/autocomplete',
      queryParameters: {
        'text': query.trim(),
        'format': 'json',
        'limit': 5,
        'lang': 'vi',
        'filter': 'rect:105.29,20.55,106.03,21.43',
        'bias': 'proximity:105.8542,21.0285',
        'apiKey': apiKey,
      },
    );
    final data = response.data;
    if (data is! Map || data['results'] is! List) return const [];
    return (data['results'] as List)
        .whereType<Map>()
        .map(
          (item) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(item)),
        )
        .whereType<PlaceSuggestion>()
        .toList(growable: false);
  }

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
      throw Exception(
        LocaleKeys.map_address_not_found.tr(namedArgs: {'address': address}),
      );
    }

    final result = Map<String, dynamic>.from(results.first as Map);

    return LatLng(
      (result['lat'] as num).toDouble(),
      (result['lon'] as num).toDouble(),
    );
  }

  Future<String?> reverseGeocode(LatLng location) async {
    final response = await _dio.get(
      'https://api.geoapify.com/v1/geocode/reverse',
      queryParameters: {
        'lat': location.latitude,
        'lon': location.longitude,
        'format': 'json',
        'limit': 1,
        'lang': 'vi',
        'apiKey': apiKey,
      },
    );

    final data = response.data;
    if (data is! Map || data['results'] is! List) return null;
    final results = data['results'] as List;
    if (results.isEmpty || results.first is! Map) return null;
    final address = (results.first as Map)['formatted'];
    if (address is! String || address.trim().isEmpty) return null;
    return address.trim();
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
