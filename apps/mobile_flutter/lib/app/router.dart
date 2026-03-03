import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/maps/presentation/maps_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/scanner/presentation/scanner_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shipment/presentation/shipment_page.dart';
import '../features/signature/presentation/signature_page.dart';
import '../features/webview_shell/presentation/webview_shell_page.dart';

WebviewBootstrap? resolveWebviewBootstrap(Object? extra) {
  if (extra is WebviewBootstrap) {
    return extra;
  }
  return null;
}

String resolveScannerType(Object? extra) {
  if (extra is Map<String, dynamic>) {
    return extra['scanType']?.toString() ?? 'default';
  }
  return 'default';
}

final GoRouter appRouter =
    GoRouter(initialLocation: '/login', routes: <RouteBase>[
  GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginPage()),
  GoRoute(
      path: '/webview',
      builder: (BuildContext context, GoRouterState state) {
        final bootstrap = resolveWebviewBootstrap(state.extra);
        if (bootstrap == null) {
          return const LoginPage();
        }
        return WebViewShellPage(bootstrap: bootstrap);
      }),
  GoRoute(
      path: '/shipment',
      builder: (BuildContext context, GoRouterState state) =>
          const ShipmentPage()),
  GoRoute(
      path: '/signature',
      builder: (BuildContext context, GoRouterState state) =>
          const SignaturePage()),
  GoRoute(
      path: '/scanner',
      builder: (BuildContext context, GoRouterState state) {
        final scanType = resolveScannerType(state.extra);
        return ScannerPage(scanType: scanType);
      }),
  GoRoute(
      path: '/maps',
      builder: (BuildContext context, GoRouterState state) => const MapsPage()),
  GoRoute(
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) =>
          const NotificationsPage()),
  GoRoute(
    path: '/settings',
    builder: (BuildContext context, GoRouterState state) =>
        const SettingsPage(),
  )
]);
