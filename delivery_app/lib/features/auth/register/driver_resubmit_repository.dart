import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:dio/dio.dart';

class RejectedDriverRequest {
  const RejectedDriverRequest({
    required this.driverId,
    required this.phoneNumber,
    required this.vehicleId,
    required this.licensePlate,
    required this.reason,
    required this.documentUrls,
  });

  final int driverId;
  final String phoneNumber;
  final int vehicleId;
  final String licensePlate;
  final String reason;
  final Map<String, String> documentUrls;

  factory RejectedDriverRequest.fromJson(Map<String, dynamic> json) {
    const documentKeys = [
      'driving_license_front_side',
      'driving_license_back_side',
      'front_side_of_the_identity_card',
      'the_back_of_the_identity_card',
    ];
    return RejectedDriverRequest(
      driverId: (json['driver_id'] as num).toInt(),
      phoneNumber: json['phone_number']?.toString() ?? '',
      vehicleId: (json['vehicle_id'] as num).toInt(),
      licensePlate: json['license_plate']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      documentUrls: {
        for (final key in documentKeys) key: json[key]?.toString() ?? '',
      },
    );
  }
}

class DriverResubmitData {
  const DriverResubmitData({
    required this.phoneNumber,
    required this.vehicleId,
    required this.licensePlate,
    this.documents = const {},
  });

  final String phoneNumber;
  final int vehicleId;
  final String licensePlate;
  final Map<String, RegisterDocument> documents;
}

abstract class DriverResubmitRepository {
  Future<RejectedDriverRequest> getRequest(int driverId);
  Future<void> resubmit(int driverId, DriverResubmitData data);
}

class DriverResubmitRemoteRepository implements DriverResubmitRepository {
  const DriverResubmitRemoteRepository(this._api);

  final ApiProvider _api;

  @override
  Future<RejectedDriverRequest> getRequest(int driverId) async {
    final response = await _api.requestApi(
      param: _DriverRequestParam(driverId),
    );
    if (response is! Map || response['data'] is! Map) {
      throw const FormatException('Invalid rejected driver response');
    }
    return RejectedDriverRequest.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<void> resubmit(int driverId, DriverResubmitData data) async {
    await _api.requestApi(param: _DriverRequestParam(driverId, data: data));
  }
}

class _DriverRequestParam extends ApiParam {
  _DriverRequestParam(this.driverId, {this.data});

  final int driverId;
  final DriverResubmitData? data;

  @override
  String get path => '/api/driver/$driverId/register-info';

  @override
  String get method => data == null ? Method.get : Method.post;

  @override
  String get contentType => data == null
      ? HeaderContentType.applicationJson
      : HeaderContentType.multipartFormData;

  @override
  bool get useMultipart => data != null;

  @override
  Future<FormData> get formData async => FormData.fromMap({
    'phone_number': data!.phoneNumber.replaceAll(' ', ''),
    'vehicle_id': data!.vehicleId,
    'license_plate': data!.licensePlate.trim(),
    for (final entry in data!.documents.entries)
      entry.key: MultipartFile.fromBytes(
        entry.value.bytes,
        filename: entry.value.name,
      ),
  });
}
