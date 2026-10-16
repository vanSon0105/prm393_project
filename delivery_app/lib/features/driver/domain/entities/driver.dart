enum DriverStatus { available, delivering, offline }

class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.plateNumber,
    required this.rating,
    required this.totalTrips,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final int totalTrips;
  final DriverStatus status;
  final DateTime joinedAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class DriverAccountRequest {
  const DriverAccountRequest({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.submittedAt,
    required this.note,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final DateTime submittedAt;
  final String note;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
