enum TripStatus { approaching, pickedUp, completed, cancelled }

class Trip {
  const Trip({
    required this.code,
    required this.date,
    required this.pickup,
    required this.destination,
    required this.service,
    required this.price,
    required this.driver,
    required this.plate,
    required this.icon,
    this.status = TripStatus.completed,
    this.paid = true,
    this.rating,
  });
  final String code,
      date,
      pickup,
      destination,
      service,
      price,
      driver,
      plate,
      icon;
  final TripStatus status;
  final bool paid;
  final int? rating;
  bool get active =>
      status == TripStatus.approaching || status == TripStatus.pickedUp;
  Trip copyWith({TripStatus? status, bool? paid, int? rating}) => Trip(
    code: code,
    date: date,
    pickup: pickup,
    destination: destination,
    service: service,
    price: price,
    driver: driver,
    plate: plate,
    icon: icon,
    status: status ?? this.status,
    paid: paid ?? this.paid,
    rating: rating ?? this.rating,
  );
}
