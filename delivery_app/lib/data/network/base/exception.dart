import 'dart:io';

class ApiException implements Exception {
  ApiException({required this.url, this.message, this.httpCode});

  factory ApiException.jsonDecodeError(String url) {
    return ApiException(
      url: url,
      httpCode: unknownHttpCode,
      message: 'invalid data',
    );
  }
  final num? httpCode;
  final String? message;
  final String url;

  static const unknownHttpCode = -1;
}

enum ApiHttpSuccessCode {
  ok(HttpStatus.ok),
  noContent(HttpStatus.noContent);

  const ApiHttpSuccessCode(this.value);
  final num value;

  static List<num> get httpsCodes =>
      ApiHttpSuccessCode.values.map((e) => e.value).toList();
}
