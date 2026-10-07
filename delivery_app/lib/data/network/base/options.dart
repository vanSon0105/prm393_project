import 'package:delivery_app/data/network/base/param.dart';
import 'package:dio/dio.dart';

extension ApiParamExt on ApiParam {
  Options get options => Options(
    method: method,
    validateStatus: (status) => validateStatus.contains(status),
    headers: headers,
  );

  Map<String, dynamic> get headers {
    final headers = <String, dynamic>{};
    headers[HeaderContentType.contentType] = contentType;
    return headers..removeWhere((key, value) => value == null || value == '');
  }
}
