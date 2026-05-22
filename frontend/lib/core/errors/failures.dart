import 'package:equatable/equatable.dart';

/// Base failure class used in the domain layer.
///
/// Failures are returned instead of throwing exceptions in the
/// repository / use-case boundary so the UI layer can handle
/// them declaratively via [AsyncValue].
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure caused by a server error.
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required String message, this.statusCode}) : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

/// Failure caused by a cache/local storage error.
class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message);
}

/// Failure caused by lack of network connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure({required String message}) : super(message);
}

/// Failure caused by a timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure({required String message}) : super(message);
}

/// Failure caused by invalid input.
class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message);
}

/// Unknown / unhandled failure.
class UnknownFailure extends Failure {
  const UnknownFailure({required String message}) : super(message);
}
