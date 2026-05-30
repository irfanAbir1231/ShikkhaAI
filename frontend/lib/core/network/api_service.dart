import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import 'dio_client.dart';

/// Centralized envelope-aware HTTP service.
///
/// Parses the backend's unified response envelope:
/// ```json
/// { "success": bool, "data": ..., "error": { "code": "...", "message": "..." } }
/// ```
/// and throws typed [AppException]s on failure.
class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  /// Performs a GET request and returns the parsed `data` payload.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Performs a POST request and returns the parsed `data` payload.
  Future<dynamic> post(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Performs a PUT request and returns the parsed `data` payload.
  Future<dynamic> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Performs a DELETE request and returns the parsed `data` payload.
  Future<dynamic> delete(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Extracts `data` from the envelope or throws a typed exception.
  dynamic _handleResponse(Response<dynamic> response) {
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      throw ServerException(
        message: 'Invalid response format from server.',
        statusCode: response.statusCode,
      );
    }

    final success = body['success'] as bool? ?? false;

    if (!success) {
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Request failed';
      final code = error?['code'] as String?;
      throw ServerException(
        message: code != null ? '[$code] $message' : message,
        statusCode: response.statusCode,
      );
    }

    return body['data'];
  }

  /// Maps [DioException] sub-types to typed [AppException]s.
  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: e.message ?? 'Request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (e.error != null && e.error.toString().contains('SocketException')) {
          return const NetworkException(
            message: 'No internet connection. Please check your network.',
          );
        }
        return ServerException(
          message: e.message ?? 'An unexpected network error occurred.',
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String message = 'Server error';
        if (data is Map<String, dynamic>) {
          final error = data['error'] as Map<String, dynamic>?;
          final msg = error?['message'] as String?;
          final code = error?['code'] as String?;
          if (msg != null) {
            message = code != null ? '[$code] $msg' : msg;
          }
        }
        return ServerException(message: message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'SSL certificate error.');
    }
  }
}
