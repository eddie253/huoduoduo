import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/bridge_action_models.dart';

abstract class UrlLauncherPort {
  Future<bool> canLaunch(Uri uri);

  Future<bool> launch(Uri uri, {required LaunchMode mode});
}

class FlutterUrlLauncherPort implements UrlLauncherPort {
  const FlutterUrlLauncherPort();

  @override
  Future<bool> canLaunch(Uri uri) {
    return canLaunchUrl(uri);
  }

  @override
  Future<bool> launch(Uri uri, {required LaunchMode mode}) {
    return launchUrl(uri, mode: mode);
  }
}

abstract class BridgeNavigationPort {
  Future<T?> push<T>(
    BuildContext context,
    String location, {
    Object? extra,
  });
}

class GoRouterNavigationPort implements BridgeNavigationPort {
  const GoRouterNavigationPort();

  @override
  Future<T?> push<T>(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    return context.push<T>(location, extra: extra);
  }
}

abstract class BridgeActionExecutor {
  Future<bool> launchExternal(Uri uri);

  Future<ScannerResult?> openScanner(
    BuildContext context, {
    required String scanType,
  });

  Future<SignatureResult?> openSignature(BuildContext context);

  Future<bool> closePage(BuildContext context);

  Future<void> showExitDialog(BuildContext context, String message);

  Future<void> redirect(BuildContext context, String page);
}

abstract class BridgeUiPort {
  Future<bool> launchExternal(Uri uri);

  Future<bool> closePage();

  Future<void> redirect(String page);

  Future<ScannerResult?> openScanner(String scanType);

  Future<SignatureResult?> openSignature();

  Future<void> showExitDialog(String message);
}

class ContextBridgeUiPort implements BridgeUiPort {
  const ContextBridgeUiPort({
    required BuildContext context,
    BridgeActionExecutor executor = const PlatformBridgeActionExecutor(),
  })  : _context = context,
        _executor = executor;

  final BuildContext _context;
  final BridgeActionExecutor _executor;

  @override
  Future<bool> launchExternal(Uri uri) => _executor.launchExternal(uri);

  @override
  Future<bool> closePage() => _executor.closePage(_context);

  @override
  Future<void> redirect(String page) => _executor.redirect(_context, page);

  @override
  Future<ScannerResult?> openScanner(String scanType) =>
      _executor.openScanner(_context, scanType: scanType);

  @override
  Future<SignatureResult?> openSignature() => _executor.openSignature(_context);

  @override
  Future<void> showExitDialog(String message) =>
      _executor.showExitDialog(_context, message);
}

class PlatformBridgeActionExecutor implements BridgeActionExecutor {
  const PlatformBridgeActionExecutor({
    UrlLauncherPort urlLauncher = const FlutterUrlLauncherPort(),
    BridgeNavigationPort navigationPort = const GoRouterNavigationPort(),
  })  : _urlLauncher = urlLauncher,
        _navigationPort = navigationPort;

  final UrlLauncherPort _urlLauncher;
  final BridgeNavigationPort _navigationPort;

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (!await _urlLauncher.canLaunch(uri)) {
      return false;
    }
    return _urlLauncher.launch(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<ScannerResult?> openScanner(
    BuildContext context, {
    required String scanType,
  }) async {
    final result = await _navigationPort.push<String>(
      context,
      '/scanner',
      extra: <String, dynamic>{'scanType': scanType},
    );
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return ScannerResult(value: result.trim(), scanType: scanType);
  }

  @override
  Future<SignatureResult?> openSignature(BuildContext context) async {
    final result = await _navigationPort.push<Map<String, dynamic>>(
      context,
      '/signature',
    );
    if (result == null) {
      return null;
    }

    final filePath = result['filePath']?.toString() ?? '';
    final fileName = result['fileName']?.toString() ?? '';
    final mimeType = result['mimeType']?.toString() ?? 'image/png';
    if (filePath.isEmpty || fileName.isEmpty) {
      return null;
    }

    return SignatureResult(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  @override
  Future<bool> closePage(BuildContext context) {
    return Navigator.of(context).maybePop();
  }

  @override
  Future<void> showExitDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Message'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Future<void> redirect(BuildContext context, String page) async {
    final normalized = page.trim();
    if (normalized.isEmpty) {
      return;
    }

    if (normalized.startsWith('/')) {
      await _navigationPort.push<void>(context, normalized);
      return;
    }

    await _navigationPort.push<void>(context, '/$normalized');
  }
}
