part of 'theme_bloc.dart';

abstract class ThemeState extends Equatable {}

class LightThemeState extends ThemeState {
  @override
  List<Object?> get props => ['light'];
}

class DarkThemeState extends ThemeState {
  @override
  List<Object?> get props => ['dark'];
}

class SystemThemeState extends ThemeState {
  @override
  List<Object?> get props => ['system'];
}

class OfflineState extends ThemeState {
  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {
  @override
  List<Object?> get props => [];
}

class OnlineState extends ThemeState {
  @override
  List<Object?> get props => [];
}
