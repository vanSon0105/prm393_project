import 'dart:convert';

TripModel tripResponseFromJson(String str) =>
    TripModel.fromJson(json.decode(str));

String tripResponseToJson(TripModel data) => json.encode(data.toJson());

class TripModel {
  final TripData? data;

  TripModel({this.data});

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    data: json["data"] == null ? null : TripData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {"data": data?.toJson()};
}

class TripData {
  final int? customerId;
  final int? driverId;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? message;
  final int? notifiedDriverCount;
  final String? statusText;
  final double? tripDistance;
  final int? tripId;
  final double? tripLatitude;
  final double? tripLongitude;
  final int? tripPrice;
  final int? tripStatusId;
  final String? driverFullName;
  final String? driverUserName;
  final String? driverPhone;
  final String? licensePlate;
  final String? vehicleType;

  TripData({
    this.customerId,
    this.driverId,
    this.destinationLatitude,
    this.destinationLongitude,
    this.message,
    this.notifiedDriverCount,
    this.statusText,
    this.tripDistance,
    this.tripId,
    this.tripLatitude,
    this.tripLongitude,
    this.tripPrice,
    this.tripStatusId,
    this.driverFullName,
    this.driverUserName,
    this.driverPhone,
    this.licensePlate,
    this.vehicleType,
  });

  /// Best available name for the assigned driver, or null when unknown.
  String? get driverDisplayName {
    for (final name in [driverFullName, driverUserName]) {
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return null;
  }

  factory TripData.fromJson(Map<String, dynamic> json) => TripData(
    customerId: json["customer_id"],
    driverId: json["driver_id"],
    destinationLatitude: json["destination_latitude"]?.toDouble(),
    destinationLongitude: json["destination_longitude"]?.toDouble(),
    message: json["message"],
    notifiedDriverCount: json["notified_driver_count"],
    statusText: json["status_text"],
    tripDistance: json["trip_distance"]?.toDouble(),
    tripId: json["trip_id"],
    tripLatitude: json["trip_latitude"]?.toDouble(),
    tripLongitude: json["trip_longitude"]?.toDouble(),
    tripPrice: (json["trip_price"] as num?)?.toInt(),
    tripStatusId: json["trip_status_id"],
    driverFullName: json["driver_full_name"],
    driverUserName: json["driver_user_name"],
    driverPhone: json["driver_phone"],
    licensePlate: json["license_plate"],
    vehicleType: json["vehicle_type"],
  );

  Map<String, dynamic> toJson() => {
    "customer_id": customerId,
    "driver_id": driverId,
    "destination_latitude": destinationLatitude,
    "destination_longitude": destinationLongitude,
    "message": message,
    "notified_driver_count": notifiedDriverCount,
    "status_text": statusText,
    "trip_distance": tripDistance,
    "trip_id": tripId,
    "trip_latitude": tripLatitude,
    "trip_longitude": tripLongitude,
    "trip_price": tripPrice,
    "trip_status_id": tripStatusId,
    "driver_full_name": driverFullName,
    "driver_user_name": driverUserName,
    "driver_phone": driverPhone,
    "license_plate": licensePlate,
    "vehicle_type": vehicleType,
  };
}
