import 'package:flutter/material.dart';

enum AppThemePreset {
  legacyOrange('legacy_orange', 'Legacy Orange', Color(0xFFFC5000)),
  azureBlue('azure_blue', 'Azure Blue', Color(0xFF1E88E5)),
  emeraldGreen('emerald_green', 'Emerald Green', Color(0xFF2E7D32)),
  rubyRed('ruby_red', 'Ruby Red', Color(0xFFD32F2F)),
  tealGreen('teal_green', 'Teal Green', Color(0xFF00897B)),
  amberGold('amber_gold', 'Amber Gold', Color(0xFFF9A825));

  const AppThemePreset(this.storageKey, this.label, this.seedColor);

  final String storageKey;
  final String label;
  final Color seedColor;

  static AppThemePreset fromStorageKey(String? raw) {
    if (raw == null || raw.isEmpty) {
      return AppThemePreset.legacyOrange;
    }
    for (final preset in AppThemePreset.values) {
      if (preset.storageKey == raw) {
        return preset;
      }
    }
    return AppThemePreset.legacyOrange;
  }
}
