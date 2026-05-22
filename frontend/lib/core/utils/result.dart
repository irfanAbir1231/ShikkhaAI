import '../errors/failures.dart';

/// A discriminated union representing either a success [T] or a [Failure].
///
/// Use [Result.success] for the happy path and [Result.failure] for errors.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get data => (this is Success<T>) ? (this as Success<T>).value : null;
  Failure? get failure => (this is FailureResult<T>) ? (this as FailureResult<T>).error : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      FailureResult<T>(:final error) => failure(error),
    };
  }

  R? whenOrNull<R>({
    R? Function(T data)? success,
    R? Function(Failure failure)? failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success?.call(value),
      FailureResult<T>(:final error) => failure?.call(error),
    };
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  T? get data => value;
}

class FailureResult<T> extends Result<T> {
  final Failure error;
  const FailureResult(this.error);

  @override
  Failure? get failure => error;
}
