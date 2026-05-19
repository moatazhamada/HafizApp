import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();
  String get errorMessage;
}

const String messageConnectionFailure = 'msg_connection_error';
const String messageInsufficientScope = 'msg_re_login_required';

class ServerFailure extends Failure {
  @override
  final String errorMessage;

  const ServerFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() {
    return 'ServerFailure{errorMessage: $errorMessage}';
  }
}

class ConnectionFailure extends Failure {
  @override
  final String errorMessage = messageConnectionFailure;

  const ConnectionFailure();

  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() {
    return 'ConnectionFailure{errorMessage: $errorMessage}';
  }
}

class CacheFailure extends Failure {
  @override
  final String errorMessage;

  const CacheFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() {
    return 'CacheFailure{errorMessage: $errorMessage}';
  }
}

class InsufficientScopeFailure extends Failure {
  @override
  final String errorMessage;

  const InsufficientScopeFailure([this.errorMessage = messageInsufficientScope]);

  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() {
    return 'InsufficientScopeFailure{errorMessage: $errorMessage}';
  }
}
