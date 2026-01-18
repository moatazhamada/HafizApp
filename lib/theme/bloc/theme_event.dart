part of 'theme_bloc.dart';

// Events
abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class ChangeThemeModeEvent extends ThemeEvent {
  final String mode;
  ChangeThemeModeEvent(this.mode);
}

class OfflineEvent extends ThemeEvent {}

class OnlineEvent extends ThemeEvent {}
