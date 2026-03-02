import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_prefs.dart';
import 'app_theme_preset.dart';
import 'theme_preference_store.dart';

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>((ref) {
  return _MemoryThemePreferenceStore();
});

class AppThemeController extends Notifier<AppThemePrefs> {
  @override
  AppThemePrefs build() {
    return ref.read(themePreferenceStoreProvider).read();
  }

  Future<void> setPreset(AppThemePreset preset) async {
    final next = state.copyWith(preset: preset);
    state = next;
    unawaited(ref.read(themePreferenceStoreProvider).write(next));
  }

  Future<void> setDarkMode(bool enabled) async {
    final next = state.copyWith(darkMode: enabled);
    state = next;
    unawaited(ref.read(themePreferenceStoreProvider).write(next));
  }
}

final appThemeControllerProvider =
    NotifierProvider<AppThemeController, AppThemePrefs>(
  AppThemeController.new,
);

class _MemoryThemePreferenceStore implements ThemePreferenceStore {
  AppThemePrefs _current = AppThemePrefs.defaults;

  @override
  AppThemePrefs read() => _current;

  @override
  Future<void> write(AppThemePrefs prefs) async {
    _current = prefs;
  }
}
