import 'package:dio/dio.dart';

/// Automatically retries requests on timeout or 5xx server errors.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.retries = 2,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = err.requestOptions.extra['retry_attempt'] as int? ?? 0;

    final shouldRetry = attempt < retries && _isRetryable(err);
    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra['retry_attempt'] = attempt + 1;
    await Future.delayed(retryDelay * (attempt + 1));

    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
