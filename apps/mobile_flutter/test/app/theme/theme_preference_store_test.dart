import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_flutter/app/theme/app_theme_prefs.dart';
import 'package:mobile_flutter/app/theme/app_theme_preset.dart';
import 'package:mobile_flutter/app/theme/theme_preference_store.dart';

void main() {
  group('SharedPreferencesThemePreferenceStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('read returns defaults when nothing is stored', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      final result = store.read();

      expect(result.preset, AppThemePreset.legacyOrange);
      expect(result.darkMode, isFalse);
    });

    test('read returns stored preset when presetKey is set', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesThemePreferenceStore.presetKey: 'azure_blue',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      final result = store.read();

      expect(result.preset, AppThemePreset.azureBlue);
      expect(result.darkMode, isFalse);
    });

    test('read returns stored darkMode when darkModeKey is set', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesThemePreferenceStore.darkModeKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      final result = store.read();

      expect(result.preset, AppThemePreset.legacyOrange);
      expect(result.darkMode, isTrue);
    });

    test('write persists preset and darkMode, then read returns them', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      await store.write(const AppThemePrefs(
        preset: AppThemePreset.rubyRed,
        darkMode: true,
      ));

      final result = store.read();
      expect(result.preset, AppThemePreset.rubyRed);
      expect(result.darkMode, isTrue);
    });

    test('write then read round-trips all presets correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      for (final preset in AppThemePreset.values) {
        await store.write(AppThemePrefs(preset: preset, darkMode: false));
        final result = store.read();
        expect(result.preset, preset, reason: 'round-trip failed for ${preset.name}');
      }
    });

    test('write overwrites previous value', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      await store.write(const AppThemePrefs(preset: AppThemePreset.tealGreen, darkMode: false));
      await store.write(const AppThemePrefs(preset: AppThemePreset.amberGold, darkMode: true));

      final result = store.read();
      expect(result.preset, AppThemePreset.amberGold);
      expect(result.darkMode, isTrue);
    });

    test('read falls back to legacyOrange for unknown stored key', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesThemePreferenceStore.presetKey: 'totally_unknown_preset',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesThemePreferenceStore(prefs);

      final result = store.read();
      expect(result.preset, AppThemePreset.legacyOrange);
    });
  });

  group('AppThemePrefs', () {
    test('defaults constant has legacyOrange and no dark mode', () {
      expect(AppThemePrefs.defaults.preset, AppThemePreset.legacyOrange);
      expect(AppThemePrefs.defaults.darkMode, isFalse);
    });

    test('copyWith overrides preset only', () {
      const original = AppThemePrefs(preset: AppThemePreset.legacyOrange, darkMode: true);
      final copy = original.copyWith(preset: AppThemePreset.emeraldGreen);
      expect(copy.preset, AppThemePreset.emeraldGreen);
      expect(copy.darkMode, isTrue);
    });

    test('copyWith overrides darkMode only', () {
      const original = AppThemePrefs(preset: AppThemePreset.azureBlue, darkMode: false);
      final copy = original.copyWith(darkMode: true);
      expect(copy.preset, AppThemePreset.azureBlue);
      expect(copy.darkMode, isTrue);
    });

    test('copyWith with no args returns equivalent object', () {
      const original = AppThemePrefs(preset: AppThemePreset.rubyRed, darkMode: true);
      final copy = original.copyWith();
      expect(copy.preset, AppThemePreset.rubyRed);
      expect(copy.darkMode, isTrue);
    });
  });
}
