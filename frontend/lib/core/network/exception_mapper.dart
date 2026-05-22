import '../errors/exceptions.dart';
import '../errors/failures.dart';

/// Maps data-layer [AppException]s to domain-layer [Failure]s.
///
/// Used by repositories to wrap caught exceptions into [Result.failure].
Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    ServerException(:final message, :final statusCode) =>
      ServerFailure(message: message, statusCode: statusCode),
    NetworkException(:final message) =>
      NetworkFailure(message: message),
    TimeoutException(:final message) =>
      TimeoutFailure(message: message),
    CacheException(:final message) =>
      CacheFailure(message: message),
    ValidationException(:final message) =>
      ValidationFailure(message: message),
    _ => UnknownFailure(message: exception.message),
  };
}
