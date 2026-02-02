import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../core/app_export.dart';

part 'theme_event.dart';

part 'theme_state.dart';

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(_getInitialState()) {
    on<ThemeEvent>(_changeTheme);
  }

  static ThemeState _getInitialState() {
    final mode = PrefUtils().getThemeMode();
    switch (mode) {
      case 'dark':
        return DarkThemeState();
      case 'light':
        return LightThemeState();
      default:
        return SystemThemeState();
    }
  }

  Future<void> _changeTheme(ThemeEvent event, Emitter<ThemeState> emit) async {
    if (event is ToggleThemeEvent) {
      final isDark = PrefUtils().getIsDarkMode();
      // Toggle between Light/Dark only, bypassing System
      final newMode = !isDark ? 'dark' : 'light';
      await PrefUtils().setThemeMode(newMode);
      emit(!isDark ? DarkThemeState() : LightThemeState());
    }

    if (event is ChangeThemeModeEvent) {
      await PrefUtils().setThemeMode(event.mode);
      switch (event.mode) {
        case 'dark':
          emit(DarkThemeState());
          break;
        case 'light':
          emit(LightThemeState());
          break;
        default:
          emit(SystemThemeState());
          break;
      }
    }

    if (event is OfflineEvent) {
      emit(OfflineState());
    }

    if (event is OnlineEvent) {
      emit(OnlineState());
    }
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as String?;
    if (mode == null) {
      // Backward compatibility: check for old isDark format
      final isDark = json['isDark'] as bool?;
      if (isDark == null) return null;
      return isDark ? DarkThemeState() : LightThemeState();
    }
    switch (mode) {
      case 'dark':
        return DarkThemeState();
      case 'light':
        return LightThemeState();
      default:
        return SystemThemeState();
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    String mode;
    if (state is DarkThemeState) {
      mode = 'dark';
    } else if (state is LightThemeState) {
      mode = 'light';
    } else if (state is SystemThemeState) {
      mode = 'system';
    } else {
      // For OfflineState, OnlineState, ThemeInitial - don't persist
      return null;
    }
    return {'mode': mode};
  }
}
