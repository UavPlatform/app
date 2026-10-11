import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.watch(sharedPreferencesProvider)),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs)
    : super(
        _prefs.getBool('dark_mode') == true ? ThemeMode.dark : ThemeMode.light,
      );
  final SharedPreferences _prefs;

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setBool('dark_mode', state == ThemeMode.dark);
  }
}
