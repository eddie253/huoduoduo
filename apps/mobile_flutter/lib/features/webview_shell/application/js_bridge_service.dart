import 'package:flutter/material.dart';
import '../domain/bridge_models.dart';

class JsBridgeService {
  Future<Map<String, dynamic>> handle(List<dynamic> args, BuildContext context) async {
    try {
      if (args.isEmpty) {
        return _error(BridgeErrorCode.invalidPayload, 'Missing bridge payload');
      }
      final message = BridgeMessage.fromDynamic(args.first);

      switch (message.method) {
        case 'error':
          return _ok('reload_requested');
        case 'RefreshEnable':
          return _ok('refresh_state_updated');
        case 'redirect':
          return _ok('redirect_received');
        case 'openfile':
          return _error(BridgeErrorCode.permissionDenied, 'File picker not wired in v1 skeleton');
        case 'open_IMG_Scanner':
          return _ok('scanner_requested');
        case 'openMsgExit':
          _showExitDialog(context, message.params['msg']?.toString() ?? 'Session expired.');
          return _ok('dialog_shown');
        case 'cfs_sign':
          return _ok('signature_requested');
        case 'APPEvent':
          return _ok('app_event_received');
        default:
          return _error(BridgeErrorCode.unsupportedMethod, 'Unsupported bridge method');
      }
    } catch (_) {
      return _error(BridgeErrorCode.runtimeError, 'Bridge runtime error');
    }
  }

  Map<String, dynamic> _ok(String action) {
    return <String, dynamic>{
      'ok': true,
      'action': action
    };
  }

  Map<String, dynamic> _error(BridgeErrorCode code, String message) {
    return <String, dynamic>{
      'ok': false,
      'error': <String, dynamic>{
        'code': code.code,
        'message': message
      }
    };
  }

  void _showExitDialog(BuildContext context, String msg) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Message'),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')
            )
          ]
        );
      }
    );
  }
}
