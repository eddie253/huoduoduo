import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../domain/bridge_action_models.dart';
import '../domain/bridge_models.dart';
import 'bridge_action_executor.dart';

class JsBridgeService {
  JsBridgeService({BridgeActionExecutor? actionExecutor})
      : _actionExecutor =
            actionExecutor ?? const PlatformBridgeActionExecutor();

  final BridgeActionExecutor _actionExecutor;

  static final Set<String> _allowedWebHosts =
      AppConfig.allowedWebHosts.map((item) => item.toLowerCase()).toSet();

  static const Set<String> _allowedMapHosts = <String>{
    'www.google.com',
    'maps.google.com',
    'maps.app.goo.gl',
  };

  Future<Map<String, dynamic>> handle(
    List<dynamic> args,
    BuildContext context,
  ) async {
    try {
      if (args.isEmpty) {
        return _error(
          BridgeErrorCode.invalidPayload,
          'Missing bridge payload',
        );
      }

      final message = BridgeMessage.fromDynamic(args.first);
      switch (message.method) {
        case 'error':
          return _ok('reload_requested');
        case 'RefreshEnable':
          return _ok(
            'refresh_state_updated',
            data: <String, dynamic>{
              'enable': message.params['enable']?.toString() ?? 'true',
            },
          );
        case 'pre_page':
          return _handleLegacyPrePage(context);
        case 'openImage':
          return _handleLegacyOpenImage(message);
        case 'redirect':
          return await _handleRedirect(message, context);
        case 'openfile':
          return await _handleOpenFile(message);
        case 'open_IMG_Scanner':
          return await _handleOpenScanner(message, context);
        case 'openMsgExit':
          return await _handleOpenMsgExit(message, context);
        case 'cfs_sign':
          return await _handleSignature(context);
        case 'APPEvent':
          return await _handleAppEvent(message, context);
        default:
          return _error(
            BridgeErrorCode.unsupportedMethod,
            'Unsupported bridge method',
          );
      }
    } on FormatException {
      return _error(
        BridgeErrorCode.invalidPayload,
        'Bridge payload format is invalid',
      );
    } catch (_) {
      return _error(
        BridgeErrorCode.runtimeError,
        'Bridge runtime error',
      );
    }
  }

  Future<Map<String, dynamic>> _handleLegacyPrePage(
    BuildContext context,
  ) async {
    final closed = await _actionExecutor.closePage(context);
    return _ok(closed ? 'legacy_pre_page_closed' : 'legacy_pre_page_ignored');
  }

  Future<Map<String, dynamic>> _handleLegacyOpenImage(
    BridgeMessage message,
  ) async {
    final url = message.params['url']?.toString() ?? '';
    final uri = _parseHttpsUri(url, allowedHosts: _allowedWebHosts);
    if (uri == null) {
      return _error(
        BridgeErrorCode.permissionDenied,
        'Legacy openImage URL is not allowed',
      );
    }
    final opened = await _actionExecutor.launchExternal(uri);
    if (!opened) {
      return _error(
        BridgeErrorCode.runtimeError,
        'Unable to open image URL',
      );
    }
    return _ok(
      'legacy_image_opened',
      data: <String, dynamic>{'url': uri.toString()},
    );
  }

  Future<Map<String, dynamic>> _handleRedirect(
    BridgeMessage message,
    BuildContext context,
  ) async {
    final page = message.params['page']?.toString() ?? '';
    if (page.trim().isEmpty) {
      return _error(
        BridgeErrorCode.invalidPayload,
        'redirect.page is required',
      );
    }

    final uri = Uri.tryParse(page);
    if (uri != null && uri.hasScheme) {
      final secured = _parseHttpsUri(
        page,
        allowedHosts: _allowedWebHosts,
      );
      if (secured == null) {
        return _error(
          BridgeErrorCode.permissionDenied,
          'Redirect URL is not allowed',
        );
      }
      final opened = await _actionExecutor.launchExternal(secured);
      if (!opened) {
        return _error(
          BridgeErrorCode.runtimeError,
          'Failed to open redirect URL',
        );
      }
      return _ok(
        'redirect_external_opened',
        data: <String, dynamic>{'url': secured.toString()},
      );
    }

    await _actionExecutor.redirect(context, page);
    return _ok(
      'redirect_received',
      data: <String, dynamic>{'page': page},
    );
  }

  Future<Map<String, dynamic>> _handleOpenFile(BridgeMessage message) async {
    final url = message.params['url']?.toString() ?? '';
    final uri = _parseHttpsUri(url, allowedHosts: _allowedWebHosts);
    if (uri == null) {
      return _error(
        BridgeErrorCode.permissionDenied,
        'File URL must be HTTPS and in allowlist',
      );
    }

    final opened = await _actionExecutor.launchExternal(uri);
    if (!opened) {
      return _error(
        BridgeErrorCode.runtimeError,
        'Unable to open file URL',
      );
    }

    return _ok(
      'file_opened',
      data: <String, dynamic>{'url': uri.toString()},
    );
  }

  Future<Map<String, dynamic>> _handleOpenScanner(
    BridgeMessage message,
    BuildContext context,
  ) async {
    final scanType = message.params['type']?.toString() ?? 'default';
    final result = await _actionExecutor.openScanner(
      context,
      scanType: scanType,
    );
    if (result == null) {
      return _ok('scanner_cancelled');
    }

    return _ok('scanner_completed', data: result.toJson());
  }

  Future<Map<String, dynamic>> _handleSignature(BuildContext context) async {
    final result = await _actionExecutor.openSignature(context);
    if (result == null) {
      return _ok('signature_cancelled');
    }

    return _ok('signature_completed', data: result.toJson());
  }

  Future<Map<String, dynamic>> _handleOpenMsgExit(
    BridgeMessage message,
    BuildContext context,
  ) async {
    final text = message.params['msg']?.toString() ?? 'Session expired.';
    await _actionExecutor.showExitDialog(context, text);
    return _ok('dialog_shown');
  }

  Future<Map<String, dynamic>> _handleAppEvent(
    BridgeMessage message,
    BuildContext context,
  ) async {
    final kindRaw = message.params['kind']?.toString() ?? '';
    final resultRaw = message.params['result']?.toString() ?? '';
    final kind = AppEventKind.fromRaw(kindRaw);

    switch (kind) {
      case AppEventKind.map:
        return _handleMapEvent(resultRaw, message.params);
      case AppEventKind.dial:
        return _handleDialEvent(resultRaw, message.params);
      case AppEventKind.close:
        final closed = await _actionExecutor.closePage(context);
        return _ok(closed ? 'page_closed' : 'page_close_ignored');
      case AppEventKind.contract:
        return _handleContractEvent(resultRaw, message.params);
      case AppEventKind.unknown:
        return _error(
          BridgeErrorCode.unsupportedMethod,
          'Unsupported APPEvent kind',
        );
    }
  }

  Future<Map<String, dynamic>> _handleMapEvent(
    String resultRaw,
    Map<String, dynamic> params,
  ) async {
    final mapUri = _resolveMapUri(resultRaw, params);
    if (mapUri == null) {
      return _error(
        BridgeErrorCode.invalidPayload,
        'APPEvent map requires valid coordinates or map URL',
      );
    }

    final opened = await _actionExecutor.launchExternal(mapUri);
    if (!opened) {
      return _error(
        BridgeErrorCode.runtimeError,
        'Failed to open map application',
      );
    }

    return _ok(
      'map_opened',
      data: <String, dynamic>{'url': mapUri.toString()},
    );
  }

  Future<Map<String, dynamic>> _handleDialEvent(
    String resultRaw,
    Map<String, dynamic> params,
  ) async {
    final phone = _normalizePhone(
      resultRaw.isEmpty ? params['phone']?.toString() ?? '' : resultRaw,
    );
    if (phone.isEmpty) {
      return _error(
        BridgeErrorCode.invalidPayload,
        'APPEvent dial requires phone number',
      );
    }

    final opened = await _actionExecutor.launchExternal(
      Uri(scheme: 'tel', path: phone),
    );
    if (!opened) {
      return _error(
        BridgeErrorCode.runtimeError,
        'Failed to open dialer',
      );
    }

    return _ok(
      'dial_opened',
      data: <String, dynamic>{'phone': phone},
    );
  }

  Future<Map<String, dynamic>> _handleContractEvent(
    String resultRaw,
    Map<String, dynamic> params,
  ) async {
    final url = resultRaw.isEmpty
        ? params['url']?.toString() ?? ''
        : resultRaw;
    final uri = _parseHttpsUri(url, allowedHosts: _allowedWebHosts);
    if (uri == null) {
      return _error(
        BridgeErrorCode.permissionDenied,
        'Contract URL is not allowed',
      );
    }

    final opened = await _actionExecutor.launchExternal(uri);
    if (!opened) {
      return _error(
        BridgeErrorCode.runtimeError,
        'Failed to open contract URL',
      );
    }

    return _ok(
      'contract_opened',
      data: <String, dynamic>{'url': uri.toString()},
    );
  }

  Uri? _resolveMapUri(String resultRaw, Map<String, dynamic> params) {
    final fromResult = Uri.tryParse(resultRaw);
    if (fromResult != null && fromResult.hasScheme) {
      final secured = _parseHttpsUri(resultRaw, allowedHosts: _allowedMapHosts);
      if (secured != null) {
        return secured;
      }
    }

    final coordinateSource = resultRaw.isEmpty
        ? '${params['latitude'] ?? ''},${params['longitude'] ?? ''}'
        : resultRaw;
    final coordinatePattern = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    );
    final match = coordinatePattern.firstMatch(coordinateSource);
    if (match == null) {
      return null;
    }

    final latitude = match.group(1);
    final longitude = match.group(2);
    return Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': '$latitude,$longitude',
    });
  }

  Uri? _parseHttpsUri(String raw, {required Set<String> allowedHosts}) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (uri.scheme.toLowerCase() != 'https' || host.isEmpty) {
      return null;
    }

    if (!allowedHosts.contains(host)) {
      return null;
    }

    return uri;
  }

  String _normalizePhone(String phone) {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+#*]'), '');
    if (sanitized.length < 5) {
      return '';
    }
    return sanitized;
  }

  Map<String, dynamic> _ok(
    String action, {
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    return BridgeActionResult(ok: true, action: action, data: data).toJson();
  }

  Map<String, dynamic> _error(
    BridgeErrorCode code,
    String message,
  ) {
    return <String, dynamic>{
      'ok': false,
      'error': <String, dynamic>{
        'code': code.code,
        'message': message,
      },
    };
  }
}
