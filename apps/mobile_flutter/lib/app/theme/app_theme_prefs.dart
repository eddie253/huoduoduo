import 'app_theme_preset.dart';

class AppThemePrefs {
  const AppThemePrefs({
    required this.preset,
    required this.darkMode,
  });

  final AppThemePreset preset;
  final bool darkMode;

  static const AppThemePrefs defaults = AppThemePrefs(
    preset: AppThemePreset.legacyOrange,
    darkMode: false,
  );

  AppThemePrefs copyWith({
    AppThemePreset? preset,
    bool? darkMode,
  }) {
    return AppThemePrefs(
      preset: preset ?? this.preset,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}
