import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme_controller.dart';
import '../../../app/theme/app_theme_preset.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const Key darkModeSwitchKey = Key('settings.darkModeSwitch');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const spacing = 12.0;
            const horizontalPadding = 16.0;
            const verticalPadding = 16.0;
            final totalHeight =
                constraints.maxHeight - (verticalPadding * 2) - (spacing * 3);
            final rowHeight = totalHeight / 4;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: rowHeight,
                    width: double.infinity,
                    child: _ThemeControlCard(
                      selectedPreset: prefs.preset,
                      isDarkMode: prefs.darkMode,
                      onPresetSelected: controller.setPreset,
                      onDarkModeChanged: controller.setDarkMode,
                    ),
                  ),
                  const SizedBox(height: spacing),
                  const Expanded(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Expanded(child: _PlaceholderCard()),
                              SizedBox(width: spacing),
                              Expanded(child: _PlaceholderCard()),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Expanded(child: _PlaceholderCard()),
                              SizedBox(width: spacing),
                              Expanded(child: _PlaceholderCard()),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Expanded(child: _PlaceholderCard()),
                              SizedBox(width: spacing),
                              Expanded(child: _PlaceholderCard()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '保留空位：6 / 6',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeControlCard extends StatelessWidget {
  const _ThemeControlCard({
    required this.selectedPreset,
    required this.isDarkMode,
    required this.onPresetSelected,
    required this.onDarkModeChanged,
  });

  final AppThemePreset selectedPreset;
  final bool isDarkMode;
  final ValueChanged<AppThemePreset> onPresetSelected;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '主題外觀',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '選擇主題色（預設：Legacy Orange）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppThemePreset.values
                  .map(
                    (preset) => _ColorOption(
                      preset: preset,
                      selected: preset == selectedPreset,
                      onTap: () => onPresetSelected(preset),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '暗黑模式',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Switch.adaptive(
                  key: SettingsPage.darkModeSwitchKey,
                  value: isDarkMode,
                  onChanged: onDarkModeChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      key: ValueKey<String>('settings.color.${preset.storageKey}'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: preset.seedColor,
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : null,
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: const SizedBox.expand(),
    );
  }
}
