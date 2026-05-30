import 'package:dio/dio.dart';

import '../../constants/storage_keys.dart';
import 'package:hive/hive.dart';

/// Attaches Bearer token to outgoing requests if available.
/// Clears local auth data on 401 responses so the user is forced to re-authenticate.
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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      try {
        final box = Hive.box<String>(StorageKeys.studentBox);
        box.delete(StorageKeys.authToken);
        box.delete(StorageKeys.studentData);
      } catch (_) {
        // Ignore Hive errors during cleanup.
      }
    }
    handler.next(err);
  }
}
