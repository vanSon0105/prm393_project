import 'package:delivery_app/features/map/data/models/trip_model.dart';
import 'package:delivery_app/features/profile/profile_repository.dart';
import 'package:latlong2/latlong.dart';

import 'data/models/route_result.dart';

enum MapTripStatus {
  idle,
  booking,
  waitingForDriver,
  driverComing,
  goingToDestination,
  completed,
  cancelled,
}

enum DriverOnlineStatus { offline, connecting, online, disconnecting }

class MapState {
  final String? errorMessage;

  final String pickupAddress;
  final String destinationAddress;
  final bool driverAddressesLoaded;
  final UserProfile? customerProfile;
  final bool customerProfileLoaded;

  final LatLng? pickup;
  final LatLng? destination;
  final LatLng? driverLocation;

  final int? tripId;
  final int? driverId;

  final RouteResult? route;
  final MapTripStatus tripStatus;

  final List<Map<String, dynamic>> pendingTrips;
  final TripModel? activeTrip;
  final DriverOnlineStatus driverOnlineStatus;

  final num? tripPrice;
  final num? tripDistance;

  const MapState({
    this.activeTrip,
    this.errorMessage,
    this.pickupAddress = '',
    this.destinationAddress = '',
    this.driverAddressesLoaded = false,
    this.customerProfile,
    this.customerProfileLoaded = false,
    this.pickup,
    this.destination,
    this.driverLocation,
    this.tripId,
    this.driverId,
    this.route,
    this.tripStatus = MapTripStatus.idle,
    this.pendingTrips = const [],
    this.driverOnlineStatus = DriverOnlineStatus.offline,
    this.tripDistance,
    this.tripPrice,
  });

  MapState copyWith({
    TripModel? activeTrip,
    String? errorMessage,
    bool clearError = false,
    String? pickupAddress,
    String? destinationAddress,
    bool? driverAddressesLoaded,
    UserProfile? customerProfile,
    bool? customerProfileLoaded,
    LatLng? pickup,
    LatLng? destination,
    LatLng? driverLocation,
    int? tripId,
    int? driverId,
    RouteResult? route,
    MapTripStatus? tripStatus,
    List<Map<String, dynamic>>? pendingTrips,
    DriverOnlineStatus? driverOnlineStatus,
    num? tripDistance,
    num? tripPrice,
  }) {
    return MapState(
      activeTrip: activeTrip ?? this.activeTrip,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      driverAddressesLoaded:
          driverAddressesLoaded ?? this.driverAddressesLoaded,
      customerProfile: customerProfile ?? this.customerProfile,
      customerProfileLoaded:
          customerProfileLoaded ?? this.customerProfileLoaded,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      driverLocation: driverLocation ?? this.driverLocation,
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      route: route ?? this.route,
      tripStatus: tripStatus ?? this.tripStatus,
      pendingTrips: pendingTrips ?? this.pendingTrips,
      driverOnlineStatus: driverOnlineStatus ?? this.driverOnlineStatus,
      tripDistance: tripDistance ?? this.tripDistance,
      tripPrice: tripPrice ?? this.tripPrice,
    );
  }

  static const int undefine = -1;
}
