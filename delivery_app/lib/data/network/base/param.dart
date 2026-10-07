import 'dart:io';

import '../../../config/environment.dart';

abstract class ApiParam {
  String get method => Method.get;

  String get path;

  List<int> get validateStatus => [HttpStatus.ok];

  String get contentType => HeaderContentType.applicationJson;

  String get url => Environment.baseUrl;

  Map<String, dynamic> get queryParameters => {};

  Map<String, dynamic> get bodyParams => {};
}

final class HeaderContentType {
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String imageJpeg = 'image/jpeg';
  static const String applicationXWwwFormUrlencoded =
      'application/x-www-form-urlencoded';
  static const String multipartFormData = 'multipart/form-data';
}

class Method {
  static const String get = 'get';
  static const String post = 'post';
  static const String patch = 'patch';
  static const String put = 'put';
  static const String delete = 'delete';
}
