class PriceModel {
  final List<PriceData>? data;

  PriceModel({this.data});

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      data: (json['data'] as List? ?? [])
          .map((item) => PriceData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static num calculatePrice(num distance, List<PriceData> configs) {
    final config = configs.firstWhere(
      (e) =>
          e.from != null &&
          e.to != null &&
          (distance >= e.from! && distance <= e.to!),
      orElse: () => PriceData(from: 0, to: 0, pricePerKm: 10000),
    );

    return distance * (config.pricePerKm ?? 0);
  }
}

class PriceData {
  final num? from;
  final num? to;
  final num? pricePerKm;

  PriceData({this.from, this.to, this.pricePerKm});

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
    from: json["from"],
    to: json["to"],
    pricePerKm: json["price_per_km"],
  );
}
