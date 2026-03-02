import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_prefs.dart';
import 'app_theme_preset.dart';

abstract class ThemePreferenceStore {
  AppThemePrefs read();
  Future<void> write(AppThemePrefs prefs);
}

class SharedPreferencesThemePreferenceStore implements ThemePreferenceStore {
  SharedPreferencesThemePreferenceStore(this._prefs);

  static const String presetKey = 'ui_theme_preset';
  static const String darkModeKey = 'ui_theme_dark_mode';

  final SharedPreferences _prefs;

  @override
  AppThemePrefs read() {
    return AppThemePrefs(
      preset: AppThemePreset.fromStorageKey(_prefs.getString(presetKey)),
      darkMode: _prefs.getBool(darkModeKey) ?? false,
    );
  }

  @override
  Future<void> write(AppThemePrefs prefs) async {
    await _prefs.setString(presetKey, prefs.preset.storageKey);
    await _prefs.setBool(darkModeKey, prefs.darkMode);
  }
}
