import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_flutter/app/theme/app_theme_controller.dart';
import 'package:mobile_flutter/app/theme/app_theme_prefs.dart';
import 'package:mobile_flutter/app/theme/app_theme_preset.dart';
import 'package:mobile_flutter/app/theme/theme_preference_store.dart';
import 'package:mobile_flutter/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('renders six theme color options and dark mode switch',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        themePreferenceStoreProvider
            .overrideWithValue(_FakeThemePreferenceStore()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    for (final preset in AppThemePreset.values) {
      expect(find.byKey(ValueKey('settings.color.${preset.storageKey}')),
          findsOneWidget);
    }
    expect(find.byKey(SettingsPage.darkModeSwitchKey), findsOneWidget);
  });

  testWidgets('updates theme prefs when selecting color and dark mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeStore = _FakeThemePreferenceStore();
    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(fakeStore)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('settings.color.azure_blue')),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(appThemeControllerProvider).preset,
      AppThemePreset.azureBlue,
    );

    await tester.ensureVisible(find.byKey(SettingsPage.darkModeSwitchKey));
    await tester.tap(find.byKey(SettingsPage.darkModeSwitchKey));
    await tester.pumpAndSettle();

    expect(container.read(appThemeControllerProvider).darkMode, isTrue);
    expect(fakeStore.lastWritten?.darkMode, isTrue);
  });
}

class _FakeThemePreferenceStore implements ThemePreferenceStore {
  AppThemePrefs _current = AppThemePrefs.defaults;
  AppThemePrefs? lastWritten;

  @override
  AppThemePrefs read() => _current;

  @override
  Future<void> write(AppThemePrefs prefs) async {
    _current = prefs;
    lastWritten = prefs;
  }
}
