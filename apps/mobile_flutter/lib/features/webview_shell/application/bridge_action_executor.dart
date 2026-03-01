import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/bridge_action_models.dart';

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

class PlatformBridgeActionExecutor implements BridgeActionExecutor {
  const PlatformBridgeActionExecutor();

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<ScannerResult?> openScanner(
    BuildContext context, {
    required String scanType,
  }) async {
    final result = await context.push<String>(
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
    final result = await context.push<Map<String, dynamic>>('/signature');
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
            )
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
      await context.push(normalized);
      return;
    }

    await context.push('/$normalized');
  }
}
