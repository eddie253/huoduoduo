import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/maps/presentation/maps_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/scanner/presentation/scanner_page.dart';
import '../features/shipment/presentation/shipment_page.dart';
import '../features/signature/presentation/signature_page.dart';
import '../features/webview_shell/presentation/webview_shell_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage()
    ),
    GoRoute(
      path: '/webview',
      builder: (BuildContext context, GoRouterState state) {
        final bootstrap = state.extra;
        if (bootstrap is! WebviewBootstrap) {
          return const LoginPage();
        }
        return WebViewShellPage(bootstrap: bootstrap);
      }
    ),
    GoRoute(
      path: '/shipment',
      builder: (BuildContext context, GoRouterState state) => const ShipmentPage()
    ),
    GoRoute(
      path: '/signature',
      builder: (BuildContext context, GoRouterState state) => const SignaturePage()
    ),
    GoRoute(
      path: '/scanner',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra;
        String scanType = 'default';
        if (extra is Map<String, dynamic>) {
          scanType = extra['scanType']?.toString() ?? scanType;
        }
        return ScannerPage(scanType: scanType);
      }
    ),
    GoRoute(
      path: '/maps',
      builder: (BuildContext context, GoRouterState state) => const MapsPage()
    ),
    GoRoute(
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) => const NotificationsPage()
    )
  ]
);
