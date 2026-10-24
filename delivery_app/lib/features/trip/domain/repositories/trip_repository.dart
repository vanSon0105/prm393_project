import '../entities/trip.dart';

abstract interface class TripRepository {
  List<Trip> getTrips();
}
