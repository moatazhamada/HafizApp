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

  /// True when this state was emitted as a result of a fresh login.
  /// UI can use this to show one-time prompts (e.g. preference sync).
  final bool isNewLogin;

  /// Full user profile from the ID token (name, email, etc.).
  final QfUserProfile? profile;

  const QfAuthAuthenticated({
    this.userId,
    this.isNewLogin = false,
    this.profile,
  });

  @override
  List<Object?> get props => [userId, isNewLogin, profile];
}

class QfAuthUnauthenticated extends QfAuthState {}

class QfAuthError extends QfAuthState {
  final String message;

  const QfAuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
