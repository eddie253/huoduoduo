import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_signal_alert_host.dart';
import 'router.dart';
import 'theme/app_theme_controller.dart';

class DidiApp extends ConsumerWidget {
  const DidiApp({super.key});

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
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: prefs.darkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
