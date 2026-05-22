import 'dart:developer';

import 'package:dio/dio.dart';

/// Logs HTTP requests and responses to the console.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('➡️ REQUEST [${options.method}] ${options.uri}');
    log('Headers: ${options.headers}');
    if (options.data != null) log('Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('✅ RESPONSE [${response.statusCode}] ${response.requestOptions.uri}');
    log('Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('❌ ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}');
    log('Message: ${err.message}');
    if (err.response?.data != null) log('Data: ${err.response?.data}');
    handler.next(err);
  }
}
