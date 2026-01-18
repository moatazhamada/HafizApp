import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../core/app_export.dart';

part 'theme_event.dart';

part 'theme_state.dart';

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc()
    : super(
        PrefUtils().getIsDarkMode() ? DarkThemeState() : LightThemeState(),
      ) {
    on<ThemeEvent>(_changeTheme);
  }

  Future<void> _changeTheme(ThemeEvent event, Emitter<ThemeState> emit) async {
    if (event is ToggleThemeEvent) {
      final isDark = PrefUtils().getIsDarkMode();
      // Deprecated: existing toggle logic toggles between Light/Dark only, bypassing System
      // We'll map 'toggle' to strictly light<->dark for now.
      final newMode = !isDark ? 'dark' : 'light';
      await PrefUtils().setThemeMode(newMode);
      await PrefUtils().setIsDarkMode(!isDark); // Keep legacy bool sync
      emit(!isDark ? DarkThemeState() : LightThemeState());
    }

    if (event is ChangeThemeModeEvent) {
      await PrefUtils().setThemeMode(event.mode);
      // Sync legacy bool for backward compatibility if needed
      if (event.mode == 'dark') {
        await PrefUtils().setIsDarkMode(true);
        emit(DarkThemeState());
      } else if (event.mode == 'light') {
        await PrefUtils().setIsDarkMode(false);
        emit(LightThemeState());
      } else {
        // System: we don't know the resolved color here easily without context,
        // but emitting *any* new state triggers main.dart rebuild.
        // Let's emit a specific state or just re-emit current to force check?
        // HydratedBloc might ignore identical state.
        // Let's emit LightThemeState as default wrapper, main.dart _getThemeMode will rule.
        emit(ThemeInitial()); // or Generic
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
    final isDark = json['isDark'] as bool?;
    if (isDark == null) return null;
    return isDark ? DarkThemeState() : LightThemeState();
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return {'isDark': state is DarkThemeState};
  }
}
