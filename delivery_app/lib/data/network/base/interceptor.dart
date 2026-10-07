import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CustomInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('REQUEST[${options.method}] => PATH: ${options.uri}');
    debugPrint('HEADER: ${options.headers}');
    debugPrint('BODY: ${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.uri}',
    );
    debugPrint('DATA: ${jsonEncode(response.data)}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.uri}, RESPONSE: ${err.response}',
    );
    super.onError(err, handler);
  }
}
