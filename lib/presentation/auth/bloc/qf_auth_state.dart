part of 'qf_auth_bloc.dart';

abstract class QfAuthState extends Equatable {
  const QfAuthState();
  
  @override
  List<Object?> get props => [];
}

class QfAuthInitial extends QfAuthState {}

class QfAuthLoading extends QfAuthState {}

class QfAuthAuthenticated extends QfAuthState {
  final String? userId;

  const QfAuthAuthenticated({this.userId});

  @override
  List<Object?> get props => [userId];
}

class QfAuthUnauthenticated extends QfAuthState {}

class QfAuthError extends QfAuthState {
  final String message;

  const QfAuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
