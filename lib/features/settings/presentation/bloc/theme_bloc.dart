import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/data/hive_database.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ToggleThemeEvent>(_onToggleTheme);
    on<LoadThemeEvent>(_onLoadTheme);
  }

  static const String _themeKey = 'theme_mode';

  void _onLoadTheme(LoadThemeEvent event, Emitter<ThemeState> emit) {
    final themeIndex = HiveDatabase.settingsBox.get(_themeKey, defaultValue: 1); // 1 = light
    final mode = themeIndex == 0 ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeState(themeMode: mode));
  }

  void _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    HiveDatabase.settingsBox.put(_themeKey, newMode == ThemeMode.dark ? 0 : 1);
    emit(ThemeState(themeMode: newMode));
  }
}
