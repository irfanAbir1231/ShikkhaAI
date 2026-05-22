/// Base exception for all app-specific errors.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a server error occurs.
class ServerException extends AppException {
  final int? statusCode;
  const ServerException({required String message, this.statusCode}) : super(message);
}

/// Thrown when a cache/local storage error occurs.
class CacheException extends AppException {
  const CacheException({required String message}) : super(message);
}

/// Thrown when there is no network connectivity.
class NetworkException extends AppException {
  const NetworkException({required String message}) : super(message);
}

/// Thrown when a request times out.
class TimeoutException extends AppException {
  const TimeoutException({required String message}) : super(message);
}

/// Thrown when the input is invalid.
class ValidationException extends AppException {
  const ValidationException({required String message}) : super(message);
}
