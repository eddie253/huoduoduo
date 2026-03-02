import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/theme/app_theme_controller.dart';
import 'app/theme/theme_preference_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        themePreferenceStoreProvider.overrideWithValue(
          SharedPreferencesThemePreferenceStore(prefs),
        ),
      ],
      child: const DidiApp(),
    ),
  );
}
