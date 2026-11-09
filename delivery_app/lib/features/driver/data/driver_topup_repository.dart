import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:dio/dio.dart';

class DriverTopupRequest {
  const DriverTopupRequest({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.proofUrl,
    required this.rejectReason,
  });

  final int id;
  final int driverId;
  final int amount;
  final String status;
  final DateTime createdAt;
  final String proofUrl;
  final String rejectReason;

  factory DriverTopupRequest.fromJson(Map<String, dynamic> json) {
    final image = json['image_transaction']?.toString() ?? '';
    final uri = Uri.tryParse(image);
    return DriverTopupRequest(
      id: (json['transaction_id'] as num).toInt(),
      driverId: (json['driver_id'] as num).toInt(),
      amount: (json['balance'] as num).toInt(),
      status: json['status']?.toString().toUpperCase() ?? '',
      createdAt: DateTime.parse(json['time'] as String),
      proofUrl: image.isEmpty || uri == null || uri.pathSegments.isEmpty
          ? ''
          : Uri.parse(Environment.baseUrl)
                .resolve('/image/${Uri.encodeComponent(uri.pathSegments.last)}')
                .toString(),
      rejectReason: json['reject_reason']?.toString() ?? '',
    );
  }
}

class DriverTopupBank {
  const DriverTopupBank({
    required this.name,
    required this.number,
    required this.holder,
    required this.qrUrl,
  });

  final String name;
  final String number;
  final String holder;
  final String qrUrl;

  factory DriverTopupBank.fromJson(Map<String, dynamic> json) {
    final qr = json['bank_qr_code']?.toString() ?? '';
    return DriverTopupBank(
      name: json['bank_name']?.toString() ?? '',
      number: json['bank_account_number']?.toString() ?? '',
      holder: json['bank_account_name']?.toString() ?? '',
      qrUrl: qr.isEmpty
          ? ''
          : Uri.parse(Environment.baseUrl)
                .resolve('/image/${Uri.encodeComponent(qr)}')
                .toString(),
    );
  }
}

class DriverTopupRepository {
  const DriverTopupRepository(this._api);

  final ApiProvider _api;

  Future<DriverTopupBank> getAdminBank() async {
    final response = await _api.requestApi(
      param: _TopupParam('/api/admin/bank-info'),
    );
    return DriverTopupBank.fromJson(_data(response));
  }

  Future<List<DriverTopupRequest>> getRequests(int driverId) async {
    final response = await _api.requestApi(
      param: _TopupParam('/api/driver/$driverId/topup/requests'),
    );
    if (response is! List) throw const FormatException('Invalid top-up list');
    return response
        .map(
          (item) => DriverTopupRequest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<DriverTopupRequest> getDetail(int id) async {
    final response = await _api.requestApi(
      param: _TopupParam('/api/topup/$id'),
    );
    return DriverTopupRequest.fromJson(_data(response));
  }

  Future<void> submit({
    required int driverId,
    required int amount,
    required String fileName,
    required List<int> imageBytes,
    int? requestId,
  }) async {
    await _api.requestApi(
      param: _TopupUploadParam(
        driverId: driverId,
        amount: amount,
        fileName: fileName,
        imageBytes: imageBytes,
        requestId: requestId,
      ),
    );
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response is! Map || response['data'] is! Map) {
      throw const FormatException('Invalid top-up response');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }
}

class _TopupParam extends ApiParam {
  _TopupParam(this.path);

  @override
  final String path;
}

class _TopupUploadParam extends ApiParam {
  _TopupUploadParam({
    required this.driverId,
    required this.amount,
    required this.fileName,
    required this.imageBytes,
    this.requestId,
  });

  final int driverId;
  final int amount;
  final String fileName;
  final List<int> imageBytes;
  final int? requestId;

  @override
  String get path => requestId == null
      ? '/api/driver/topup'
      : '/api/driver/topup/$requestId/update';

  @override
  String get method => requestId == null ? Method.post : Method.put;

  @override
  String get contentType => HeaderContentType.multipartFormData;

  @override
  bool get useMultipart => true;

  @override
  Future<FormData> get formData async => FormData.fromMap({
    'driver_id': driverId,
    'balance': amount,
    'image_transaction': MultipartFile.fromBytes(
      imageBytes,
      filename: fileName,
    ),
  });
}
