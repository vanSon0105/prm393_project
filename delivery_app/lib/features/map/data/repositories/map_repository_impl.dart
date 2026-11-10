import 'dart:convert';

import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:delivery_app/features/map/data/repositories/accept_trip_param.dart';
import 'package:delivery_app/features/map/data/repositories/book_param.dart';
import 'package:delivery_app/features/map/data/repositories/complete_trip_param.dart';
import 'package:delivery_app/features/map/data/repositories/start_trip_param.dart';
import 'package:delivery_app/features/map/data/repositories/trip_param.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/network/base/provider.dart';
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl extends MapRepository {
  final ApiProvider apiProvider;

  MapRepositoryImpl(this.apiProvider);

  @override
  Future<TripModel?> getTripActive({required int customerId}) async {
    try {
      return await apiProvider.requestApi(param: TripParam(customerId));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> bookTrip({
    required int customerId,
    required int tripDistanceKm,
    required LatLng pickup,
    required LatLng destination,
  }) async {
    final response = await apiProvider.requestApi(
      param: BookParam(
        customerId: customerId,
        tripDistanceKm: tripDistanceKm,
        pickup: pickup,
        destination: destination,
      ),
    );
    return TripModel.fromJson(response).data?.tripId ?? 0;
  }

  @override
  Future<void> acceptTrip({required int driverId, required int tripId}) async {
    final response = await apiProvider.requestApi(
      param: AcceptTripParam(tripId: tripId, driverId: driverId),
    );
    debugPrint('------- Accept trip : $response');
  }

  @override
  Future<void> startTrip({required int driverId, required int tripId}) async {
    final response = await apiProvider.requestApi(
      param: StartTripParam(tripId: tripId, driverId: driverId),
    );
    debugPrint('------- Start trip : $response');
  }

  @override
  Future<void> completeTrip({
    required int driverId,
    required int tripId,
  }) async {
    final response = await apiProvider.requestApi(
      param: CompleteTripParam(tripId: tripId, driverId: driverId),
    );
    debugPrint('------- Complete trip : $response');
  }

  Map<String, dynamic> _responseBody(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(data) as Map);
      } catch (_) {
        return {'error': data};
      }
    }
    return <String, dynamic>{};
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'] ?? body['message'];
    return error?.toString().isNotEmpty == true ? error.toString() : fallback;
  }

  @override
  Future<void> cancelCustomerTrip({
    required int customerId,
    required int tripId,
  }) {
    // TODO: implement cancelCustomerTrip
    throw UnimplementedError();
  }

  @override
  Future<void> cancelDriverTrip({required int driverId, required int tripId}) {
    // TODO: implement cancelDriverTrip
    throw UnimplementedError();
  }
}
