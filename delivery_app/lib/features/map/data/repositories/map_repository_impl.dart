import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:delivery_app/features/map/data/repositories/accept_trip_param.dart';
import 'package:delivery_app/features/map/data/repositories/active_driver_trip_param.dart';
import 'package:delivery_app/features/map/data/repositories/book_param.dart';
import 'package:delivery_app/features/map/data/repositories/cancel_customer_trip_param.dart';
import 'package:delivery_app/features/map/data/repositories/cancel_driver_trip_param.dart';
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
    final response = await apiProvider.requestApi(param: TripParam(customerId));
    if (response is! Map) {
      throw const FormatException('Invalid active trip response');
    }
    return TripModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<TripModel?> getActiveDriverTrip({required int driverId}) async {
    final response = await apiProvider.requestApi(
      param: ActiveDriverTripParam(driverId),
    );
    if (response is! Map) {
      throw const FormatException('Invalid active driver trip response');
    }
    return TripModel.fromJson(Map<String, dynamic>.from(response));
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

  @override
  Future<void> cancelCustomerTrip({
    required int customerId,
    required int tripId,
  }) async {
    await apiProvider.requestApi(
      param: CancelCustomerTripParam(tripId: tripId, customerId: customerId),
    );
  }

  @override
  Future<void> cancelDriverTrip({
    required int driverId,
    required int tripId,
  }) async {
    await apiProvider.requestApi(
      param: CancelDriverTripParam(tripId: tripId, driverId: driverId),
    );
  }
}
