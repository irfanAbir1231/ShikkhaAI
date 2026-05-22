import 'package:dio/dio.dart';

import '../../constants/storage_keys.dart';
import 'package:hive/hive.dart';

/// Attaches Bearer token to outgoing requests if available.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final box = await Hive.openBox<String>(StorageKeys.settingsBox);
      final token = box.get('auth_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // No token available; continue without auth header.
    }
    handler.next(options);
  }
}
