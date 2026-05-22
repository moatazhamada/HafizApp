import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';

/// Extensions on [Failure] to provide standard localized error messages.
extension FailureX on Failure {
  /// Returns a standard localized message key based on the failure type.
  ///
  /// - [ServerFailure] → `'msg_server_error'`
  /// - [ConnectionFailure] → `'msg_connection_error'`
  /// - [CacheFailure] → `'msg_cache_error'`
  /// - [InsufficientScopeFailure] → the failure's own [errorMessage]
  /// - Any other failure → [errorMessage]
  String get localizedMessage {
    return switch (this) {
      ServerFailure() => 'msg_server_error',
      ConnectionFailure() => 'msg_connection_error',
      CacheFailure() => 'msg_cache_error',
      InsufficientScopeFailure() => errorMessage,
      _ => errorMessage,
    };
  }
}

/// Extensions on [Either<Failure, T>] to simplify repetitive fold patterns.
extension EitherX<T> on Either<Failure, T> {
  /// Folds the [Either] into a single value, mapping failures to their
  /// [localizedMessage] automatically.
  ///
  /// Example:
  /// ```dart
  /// final state = result.foldWithMessage(
  ///   onFailure: (msg) => HifzError(msg),
  ///   onSuccess: (data) => HifzLoaded(data),
  /// );
  /// ```
  R foldWithMessage<R>({
    required R Function(String message) onFailure,
    required R Function(T data) onSuccess,
  }) {
    return fold(
      (failure) => onFailure(failure.localizedMessage),
      (data) => onSuccess(data),
    );
  }
}
