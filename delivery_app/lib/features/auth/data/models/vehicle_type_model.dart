class VehicleTypeModel {
  final List<VehicleTypeData>? data;

  VehicleTypeModel({this.data});

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      data: (json['data'] as List? ?? [])
          .map((item) => VehicleTypeData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data?.map((item) => item.toJson()).toList()};
  }
}

class VehicleTypeData {
  final int? id;
  final String? name;

  VehicleTypeData({this.id, this.name});

  factory VehicleTypeData.fromJson(Map<String, dynamic> json) {
    return VehicleTypeData(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
