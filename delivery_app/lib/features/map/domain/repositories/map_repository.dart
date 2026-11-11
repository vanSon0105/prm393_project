import 'package:delivery_app/features/map/data/models/price_model.dart';
import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:latlong2/latlong.dart';

abstract class MapRepository {
  Future<TripModel?> getTripActive({required int customerId});
  Future<TripModel?> getActiveDriverTrip({required int driverId});

  Future<PriceModel> getPriceConfig();

  Future<int> bookTrip({
    required int customerId,
    required int tripDistanceKm,
    required LatLng pickup,
    required LatLng destination,
  });

  Future<void> acceptTrip({required int driverId, required int tripId});

  Future<void> startTrip({required int driverId, required int tripId});

  /// Completes the trip and returns the commission deducted from the
  /// driver's wallet, when the server reports it.
  Future<int?> completeTrip({required int driverId, required int tripId});

  Future<void> cancelCustomerTrip({
    required int customerId,
    required int tripId,
  });

  Future<void> cancelDriverTrip({required int driverId, required int tripId});
}
