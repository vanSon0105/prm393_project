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
  });

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
    tripPrice: json["trip_price"],
    tripStatusId: json["trip_status_id"],
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
  };
}
