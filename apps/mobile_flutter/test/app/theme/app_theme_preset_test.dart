import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/app/theme/app_theme_preset.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('AppThemePreset.fromStorageKey', () {
    test('returns legacyOrange for null key', () {
      expect(AppThemePreset.fromStorageKey(null), AppThemePreset.legacyOrange);
    });

    test('returns legacyOrange for empty string', () {
      expect(AppThemePreset.fromStorageKey(''), AppThemePreset.legacyOrange);
    });

    test('returns legacyOrange for unknown key', () {
      expect(AppThemePreset.fromStorageKey('does_not_exist'),
          AppThemePreset.legacyOrange);
    });

    test('resolves legacy_orange', () {
      expect(AppThemePreset.fromStorageKey('legacy_orange'),
          AppThemePreset.legacyOrange);
    });

    test('resolves azure_blue', () {
      expect(AppThemePreset.fromStorageKey('azure_blue'),
          AppThemePreset.azureBlue);
    });

    test('resolves emerald_green', () {
      expect(AppThemePreset.fromStorageKey('emerald_green'),
          AppThemePreset.emeraldGreen);
    });

    test('resolves ruby_red', () {
      expect(AppThemePreset.fromStorageKey('ruby_red'), AppThemePreset.rubyRed);
    });

    test('resolves teal_green', () {
      expect(AppThemePreset.fromStorageKey('teal_green'),
          AppThemePreset.tealGreen);
    });

    test('resolves amber_gold', () {
      expect(AppThemePreset.fromStorageKey('amber_gold'),
          AppThemePreset.amberGold);
    });
  });

  group('AppThemePreset enum properties', () {
    test('all presets have non-empty storageKey', () {
      for (final preset in AppThemePreset.values) {
        expect(preset.storageKey, isNotEmpty,
            reason: '${preset.name} storageKey must not be empty');
      }
    });

    test('all presets have non-empty label', () {
      for (final preset in AppThemePreset.values) {
        expect(preset.label, isNotEmpty,
            reason: '${preset.name} label must not be empty');
      }
    });

    test('all presets have a non-transparent seedColor', () {
      for (final preset in AppThemePreset.values) {
        expect(preset.seedColor, isNotNull,
            reason: '${preset.name} seedColor must not be null');
        expect(preset.seedColor.alpha, greaterThan(0),
            reason: '${preset.name} seedColor must be opaque');
      }
    });

    test('all storageKeys are unique', () {
      final keys = AppThemePreset.values.map((p) => p.storageKey).toList();
      expect(keys.toSet().length, equals(keys.length));
    });

    test('fromStorageKey round-trips every preset', () {
      for (final preset in AppThemePreset.values) {
        expect(
            AppThemePreset.fromStorageKey(preset.storageKey), equals(preset));
      }
    });

    test('legacyOrange seedColor is orange-ish', () {
      final color = AppThemePreset.legacyOrange.seedColor;
      expect(color.red, greaterThan(200));
      expect(color.green, lessThan(150));
      expect(color.blue, lessThan(50));
    });

    test('azureBlue seedColor is blue-dominant', () {
      final color = AppThemePreset.azureBlue.seedColor;
      expect(color.blue, greaterThan(color.red));
    });
  });
}
