import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_signal_alert_host.dart';
import 'router.dart';
import 'theme/app_theme_controller.dart';

class DidiApp extends ConsumerWidget {
  const DidiApp({super.key});

  ColorScheme _buildLightScheme(Color seed) {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return base.copyWith(
      primary: seed,
      onPrimary: Colors.white,
      secondary: seed,
      onSecondary: Colors.white,
      surface: const Color(0xFFFFFBF8),
      onSurface: const Color(0xFF1F1F1F),
      onSurfaceVariant: const Color(0xFF666666),
      outline: const Color(0xFFC7C7C7),
      outlineVariant: const Color(0xFFE6E6E6),
      inverseSurface: seed,
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFFFB38A),
    );
  }

  ColorScheme _buildDarkScheme(Color seed) {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return base.copyWith(
      primary: seed,
      onPrimary: const Color(0xFF301300),
      secondary: seed,
      onSecondary: const Color(0xFF301300),
      surface: const Color(0xFF1A1715),
      onSurface: const Color(0xFFEDE1D9),
      onSurfaceVariant: const Color(0xFFBBB0A8),
      outline: const Color(0xFF8A7F79),
      outlineVariant: const Color(0xFF544A45),
      inverseSurface: const Color(0xFFEDE1D9),
      onInverseSurface: const Color(0xFF2C2724),
      inversePrimary: seed,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appThemeControllerProvider);
    final seed = prefs.preset.seedColor;

    return MaterialApp.router(
      title: 'Didi Express',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) {
        return NetworkSignalAlertHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorScheme: _buildLightScheme(seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: _buildDarkScheme(seed),
        useMaterial3: true,
      ),
      themeMode: prefs.darkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
