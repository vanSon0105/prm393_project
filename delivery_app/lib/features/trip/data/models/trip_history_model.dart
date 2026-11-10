class TripHistoryEntry {
  const TripHistoryEntry({
    required this.tripId,
    required this.statusId,
    required this.customerName,
    required this.driverName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.distanceKm,
    this.price,
    this.reviewVote,
    this.reviewComment,
  });

  final int tripId;
  final int statusId;
  final String customerName;
  final String? driverName;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final int? distanceKm;
  final double? price;
  final int? reviewVote;
  final String? reviewComment;

  bool get isCompleted => statusId == 4;

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) {
    num? optionalNumber(String key) =>
        json[key] is num ? json[key] as num : null;
    num requiredNumber(String key) =>
        optionalNumber(key) ??
        (throw FormatException('Missing trip history field: $key'));

    return TripHistoryEntry(
      tripId: requiredNumber('trip_id').toInt(),
      statusId: requiredNumber('trip_status_id').toInt(),
      customerName: json['customer_name']?.toString() ?? '',
      driverName: json['driver_name']?.toString(),
      pickupLatitude: requiredNumber('trip_latitude').toDouble(),
      pickupLongitude: requiredNumber('trip_longitude').toDouble(),
      destinationLatitude: requiredNumber('destination_latitude').toDouble(),
      destinationLongitude: requiredNumber('destination_longitude').toDouble(),
      distanceKm: optionalNumber('trip_distance')?.toInt(),
      price: optionalNumber('trip_price')?.toDouble(),
      reviewVote: optionalNumber('review_vote')?.toInt(),
      reviewComment: json['review_comment']?.toString(),
    );
  }
}

class TripHistoryPageData {
  const TripHistoryPageData({required this.entries, required this.hasMore});

  final List<TripHistoryEntry> entries;
  final bool hasMore;

  factory TripHistoryPageData.fromJson(dynamic response) {
    if (response is! Map ||
        response['data'] is! List ||
        response['has_more'] is! bool) {
      throw const FormatException('Invalid trip history response');
    }
    return TripHistoryPageData(
      entries: (response['data'] as List)
          .map(
            (entry) => TripHistoryEntry.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      hasMore: response['has_more'] as bool,
    );
  }
}
