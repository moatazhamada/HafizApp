part of 'qf_auth_bloc.dart';

abstract class QfAuthEvent extends Equatable {
  const QfAuthEvent();

  @override
  List<Object> get props => [];
}

class QfAuthCheckRequested extends QfAuthEvent {}

class QfAuthLoginRequested extends QfAuthEvent {}

class QfAuthLogoutRequested extends QfAuthEvent {}
