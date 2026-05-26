import 'package:dio/dio.dart';

import '../../constants/storage_keys.dart';
import 'package:hive/hive.dart';

/// Attaches Bearer token to outgoing requests if available.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final box = Hive.box<String>(StorageKeys.studentBox);
      final token = box.get(StorageKeys.authToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // No token available; continue without auth header.
    }
    handler.next(options);
  }
}
