import '../../domain/entities/driver.dart';

class DriverModel extends Driver {
  const DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.vehicle,
    required super.plateNumber,
    required super.rating,
    required super.totalTrips,
    required super.status,
    required super.joinedAt,
  });

  factory DriverModel.fromJson(Map<String, Object?> json) {
    return DriverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      vehicle: json['vehicle'] as String,
      plateNumber: json['plateNumber'] as String,
      rating: json['rating'] as double,
      totalTrips: json['totalTrips'] as int,
      status: DriverStatus.values.byName(json['status'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}

class DriverAccountRequestModel extends DriverAccountRequest {
  const DriverAccountRequestModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.vehicleType,
    required super.submittedAt,
    required super.note,
  });

  factory DriverAccountRequestModel.fromJson(Map<String, Object?> json) {
    return DriverAccountRequestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      vehicleType: json['vehicleType'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      note: json['note'] as String,
    );
  }
}
