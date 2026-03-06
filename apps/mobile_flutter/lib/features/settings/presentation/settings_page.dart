import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme/app_theme_controller.dart';
import '../../../app/theme/app_theme_preset.dart';
import '../../scanner/presentation/scanner_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const Key darkModeSwitchKey = Key('settings.darkModeSwitch');
  static const Key versionTextKey = Key('settings.version.text');
  static const Key scanTestCardKey = Key('settings.scanTest.card');
  static const Key scanTestButtonKey = Key('settings.scanTest.button');
  static const Key scanTestHistoryKey = Key('settings.scanTest.history');

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final Future<String> _versionFuture = _loadVersion();
  String? _lastTestResult;

  Future<String> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '主題色',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppThemePreset.values.map((preset) {
                      final selected = preset == prefs.preset;
                      return InkWell(
                        key: ValueKey<String>(
                            'settings.color.${preset.storageKey}'),
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => controller.setPreset(preset),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? colors.primary
                                  : colors.outlineVariant,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: preset.seedColor,
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '暗黑模式',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Switch.adaptive(
                        key: SettingsPage.darkModeSwitchKey,
                        value: prefs.darkMode,
                        onChanged: controller.setDarkMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            key: SettingsPage.scanTestCardKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '條碼掃描測試',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '測試模式：掃描結果僅記錄於本機診斷日誌，不送出後端。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (_lastTestResult != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.qr_code, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastTestResult!,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          key: SettingsPage.scanTestButtonKey,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('開始掃描測試'),
                          onPressed: () async {
                            final result =
                                await Navigator.of(context).push<String>(
                              MaterialPageRoute<String>(
                                builder: (_) =>
                                    const ScannerPage(scanType: 'barcode_test'),
                                fullscreenDialog: true,
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() => _lastTestResult = result);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: SettingsPage.scanTestHistoryKey,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('查看掃描診斷記錄'),
                    onPressed: () => context.push('/scan-diagnostics'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<String>(
                future: _versionFuture,
                builder: (context, snapshot) {
                  final value = snapshot.data ?? 'loading...';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'App Version',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(value, key: SettingsPage.versionTextKey),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
