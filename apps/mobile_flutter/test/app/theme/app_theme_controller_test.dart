import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_flutter/app/theme/app_theme_controller.dart';
import 'package:mobile_flutter/app/theme/app_theme_prefs.dart';
import 'package:mobile_flutter/app/theme/app_theme_preset.dart';
import 'package:mobile_flutter/app/theme/theme_preference_store.dart';

void main() {
  test('build reads current prefs from store', () {
    final fakeStore = _FakeThemePreferenceStore(
      initial: const AppThemePrefs(
        preset: AppThemePreset.tealGreen,
        darkMode: true,
      ),
    );

    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(fakeStore)],
    );
    addTearDown(container.dispose);

    final state = container.read(appThemeControllerProvider);
    expect(state.preset, AppThemePreset.tealGreen);
    expect(state.darkMode, isTrue);
  });

  test('setPreset updates state and persists', () async {
    final fakeStore = _FakeThemePreferenceStore();
    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(fakeStore)],
    );
    addTearDown(container.dispose);

    await container
        .read(appThemeControllerProvider.notifier)
        .setPreset(AppThemePreset.rubyRed);

    final state = container.read(appThemeControllerProvider);
    expect(state.preset, AppThemePreset.rubyRed);
    expect(fakeStore.lastWritten?.preset, AppThemePreset.rubyRed);
  });

  test('setDarkMode updates state and persists', () async {
    final fakeStore = _FakeThemePreferenceStore();
    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(fakeStore)],
    );
    addTearDown(container.dispose);

    await container.read(appThemeControllerProvider.notifier).setDarkMode(true);

    final state = container.read(appThemeControllerProvider);
    expect(state.darkMode, isTrue);
    expect(fakeStore.lastWritten?.darkMode, isTrue);
  });
}

class _FakeThemePreferenceStore implements ThemePreferenceStore {
  _FakeThemePreferenceStore({AppThemePrefs? initial})
      : _current = initial ?? AppThemePrefs.defaults;

  AppThemePrefs _current;
  AppThemePrefs? lastWritten;

  @override
  AppThemePrefs read() => _current;

  @override
  Future<void> write(AppThemePrefs prefs) async {
    _current = prefs;
    lastWritten = prefs;
  }
}
