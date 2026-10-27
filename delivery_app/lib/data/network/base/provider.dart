import 'dart:convert';
import 'dart:io';

import 'package:delivery_app/data/network/base/param.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'exception.dart';
import 'options.dart';

part 'provider.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.2.14:8080',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
}

@Riverpod(keepAlive: true)
ApiProvider apiProvider(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiProvider(dio);
}

class ApiProvider {
  final Dio _dio;

  ApiProvider(this._dio);

  Future<dynamic> requestApi({required ApiParam param}) async {
    final url = param.url + param.path;
    final body = param.bodyParams..removeWhere((key, value) => value == null);
    final bodyRequest =
        (param.contentType == HeaderContentType.applicationXWwwFormUrlencoded
        ? body
        : jsonEncode(body));

    try {
      final response = await _dio.request<dynamic>(
        url,
        data: bodyRequest,
        queryParameters: param.queryParameters
          ..removeWhere((k, v) => v == null),
        options: param.options,
      );
      return response.data;
    } on SocketException catch (e) {
      debugPrint(e.message);
      throw ApiException(url: url);
    } on DioException catch (e) {
      debugPrint(e.message);
      if (e.type == DioExceptionType.cancel) return null;

      final httpStatus = e.response?.statusCode;
      final data = e.response?.data;
      final message = _getErrorMessage(data);
      throw ApiException(httpCode: httpStatus, message: message, url: url);
    } catch (e) {
      throw ApiException(message: e.toString(), url: url);
    }
  }

  String? _getErrorMessage(dynamic errorResponse) {
    /// TODO: Get error message
    return null;
  }
}
