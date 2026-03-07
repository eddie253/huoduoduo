import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../domain/bridge_action_models.dart';
import '../domain/bridge_models.dart';
import 'bridge_action_executor.dart';
import 'map_navigation_preflight_service.dart';

class JsBridgeService {
  JsBridgeService({
    MapNavigationPreflightPort? mapNavigationPreflight,
  }) : _mapNavigationPreflight = mapNavigationPreflight ??
            const DefaultMapNavigationPreflightService();

  final MapNavigationPreflightPort _mapNavigationPreflight;

  static final Set<String> _allowedWebHosts =
      AppConfig.allowedWebHosts.map((item) => item.toLowerCase()).toSet();

  static const Set<String> _allowedMapHosts = <String>{
    'www.google.com',
    'maps.google.com',
    'maps.app.goo.gl',
  };

  static const Set<String> _allowedExternalMapSchemes = <String>{
    'geo',
    'google.navigation',
    'comgooglemaps',
    'intent',
  };

  Future<Map<String, dynamic>> handle(
    List<dynamic> args,
    BridgeUiPort uiPort,
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
          return _handleLegacyPrePage(uiPort);
        case 'openImage':
          return _handleLegacyOpenImage(message, uiPort);
        case 'redirect':
          return await _handleRedirect(message, uiPort);
        case 'openfile':
          return await _handleOpenFile(message, uiPort);
        case 'open_IMG_Scanner':
          return await _handleOpenScanner(message, uiPort);
        case 'openMsgExit':
          return await _handleOpenMsgExit(message, uiPort);
        case 'cfs_sign':
          return await _handleSignature(uiPort);
        case 'APPEvent':
          return await _handleAppEvent(message, uiPort);
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
    BridgeUiPort uiPort,
  ) async {
    final closed = await uiPort.closePage();
    return _ok(closed ? 'legacy_pre_page_closed' : 'legacy_pre_page_ignored');
  }

  Future<Map<String, dynamic>> _handleLegacyOpenImage(
    BridgeMessage message,
    BridgeUiPort uiPort,
  ) async {
    final url = message.params['url']?.toString() ?? '';
    final uri = _parseHttpsUri(url, allowedHosts: _allowedWebHosts);
    if (uri == null) {
      return _error(
        BridgeErrorCode.permissionDenied,
        'Legacy openImage URL is not allowed',
      );
    }
    final opened = await uiPort.launchExternal(uri);
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
    BridgeUiPort uiPort,
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
      final opened = await uiPort.launchExternal(secured);
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

    await uiPort.redirect(page);
    return _ok(
      'redirect_received',
      data: <String, dynamic>{'page': page},
    );
  }

  Future<Map<String, dynamic>> _handleOpenFile(
    BridgeMessage message,
    BridgeUiPort uiPort,
  ) async {
    final url = message.params['url']?.toString() ?? '';
    final uri = _parseHttpsUri(url, allowedHosts: _allowedWebHosts);
    if (uri == null) {
      return _error(
        BridgeErrorCode.permissionDenied,
        'File URL must be HTTPS and in allowlist',
      );
    }

    final opened = await uiPort.launchExternal(uri);
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
    BridgeUiPort uiPort,
  ) async {
    final scanType = message.params['type']?.toString() ?? 'default';
    final result = await uiPort.openScanner(scanType);
    if (result == null) {
      return _ok('scanner_cancelled');
    }

    return _ok('scanner_completed', data: result.toJson());
  }

  Future<Map<String, dynamic>> _handleSignature(BridgeUiPort uiPort) async {
    final result = await uiPort.openSignature();
    if (result == null) {
      return _ok('signature_cancelled');
    }

    return _ok('signature_queued', data: <String, dynamic>{
      ...result.toJson(),
      'uploadStatus': 'queued',
    });
  }

  Future<Map<String, dynamic>> _handleOpenMsgExit(
    BridgeMessage message,
    BridgeUiPort uiPort,
  ) async {
    final text = message.params['msg']?.toString() ?? 'Session expired.';
    await uiPort.showExitDialog(text);
    return _ok('dialog_shown');
  }

  Future<Map<String, dynamic>> _handleAppEvent(
    BridgeMessage message,
    BridgeUiPort uiPort,
  ) async {
    final kindRaw = message.params['kind']?.toString() ?? '';
    final resultRaw = message.params['result']?.toString() ?? '';
    final kind = AppEventKind.fromRaw(kindRaw);

    switch (kind) {
      case AppEventKind.map:
        return _handleMapEvent(resultRaw, message.params, uiPort);
      case AppEventKind.dial:
        return _handleDialEvent(resultRaw, message.params, uiPort);
      case AppEventKind.close:
        final closed = await uiPort.closePage();
        return _ok(closed ? 'page_closed' : 'page_close_ignored');
      case AppEventKind.contract:
        return _handleContractEvent(resultRaw, message.params, uiPort);
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
    BridgeUiPort uiPort,
  ) async {
    final mapUri = _resolveMapUri(resultRaw, params);
    if (mapUri == null) {
      return _error(
        BridgeErrorCode.invalidPayload,
        'APPEvent map requires valid coordinates or map URL',
      );
    }

    final preflight = await _mapNavigationPreflight.ensureReady();
    if (!preflight.allowed) {
      final preflightMessage = preflight.message?.trim();
      return _error(
        BridgeErrorCode.permissionDenied,
        preflightMessage == null || preflightMessage.isEmpty
            ? 'Navigation preflight failed.'
            : preflightMessage,
      );
    }

    final opened = await uiPort.launchExternal(mapUri);
    if (!opened) {
      final Uri? fallbackMapUri = _buildWebFallbackMapUri(mapUri);
      if (fallbackMapUri != null) {
        final fallbackOpened = await uiPort.launchExternal(fallbackMapUri);
        if (fallbackOpened) {
          return _ok(
            'map_opened',
            data: <String, dynamic>{'url': fallbackMapUri.toString()},
          );
        }
      }
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
    BridgeUiPort uiPort,
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

    final opened = await uiPort.launchExternal(
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
    BridgeUiPort uiPort,
  ) async {
    final url = resultRaw.isEmpty ? params['url']?.toString() ?? '' : resultRaw;
    final uri = _parseHttpsUri(url, allowedHosts: _allowedWebHosts);
    if (uri == null) {
      return _error(
        BridgeErrorCode.permissionDenied,
        'Contract URL is not allowed',
      );
    }

    final opened = await uiPort.launchExternal(uri);
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
    final trimmedResult = resultRaw.trim();
    final fromResult = Uri.tryParse(trimmedResult);
    if (fromResult != null && fromResult.hasScheme) {
      final scheme = fromResult.scheme.toLowerCase();
      final host = fromResult.host.toLowerCase();
      if ((scheme == 'https' || scheme == 'http') &&
          _allowedMapHosts.contains(host)) {
        if (scheme == 'https') {
          return fromResult;
        }
        return fromResult.replace(scheme: 'https');
      }
      if (_allowedExternalMapSchemes.contains(scheme)) {
        return fromResult;
      }
    }

    final Map<String, dynamic>? resultPayload =
        _tryParseMapPayloadObject(trimmedResult);
    if (resultPayload != null) {
      final destination = _firstNonEmpty(
        resultPayload,
        const <String>['adr', 'address', 'destination', 'daddr', 'query'],
      );
      final origin = _firstNonEmpty(
        resultPayload,
        const <String>['latlng', 'origin', 'saddr'],
      );
      if (destination != null) {
        return _buildGoogleNavigationUri(
          destination: _sanitizeMapDestination(destination),
          origin: origin,
        );
      }
      final coords = _firstNonEmpty(
        resultPayload,
        const <String>['coordinate', 'coordinates', 'latlng'],
      );
      final fromCoordinates = _buildGoogleMapUriFromCoordinate(coords ?? '');
      if (fromCoordinates != null) {
        return fromCoordinates;
      }
    }

    final fromResultCoordinates =
        _buildGoogleMapUriFromCoordinate(trimmedResult);
    if (fromResultCoordinates != null) {
      return fromResultCoordinates;
    }

    if (trimmedResult.isNotEmpty) {
      return _buildGoogleNavigationUri(
        destination: _sanitizeMapDestination(trimmedResult),
      );
    }

    final coordinateSource =
        '${params['latitude'] ?? ''},${params['longitude'] ?? ''}';
    final fromParamCoordinates =
        _buildGoogleMapUriFromCoordinate(coordinateSource);
    if (fromParamCoordinates != null) {
      return fromParamCoordinates;
    }

    final destination = _firstNonEmpty(
      params,
      const <String>['adr', 'address', 'destination', 'daddr', 'query'],
    );
    if (destination != null) {
      final origin =
          _firstNonEmpty(params, const <String>['latlng', 'origin', 'saddr']);
      return _buildGoogleNavigationUri(
        destination: _sanitizeMapDestination(destination),
        origin: origin,
      );
    }

    return null;
  }

  Map<String, dynamic>? _tryParseMapPayloadObject(String raw) {
    final json = _tryParseJsonObject(raw);
    if (json != null) {
      return json;
    }
    return _tryParseLegacyMapObject(raw);
  }

  Map<String, dynamic>? _tryParseJsonObject(String raw) {
    if (raw.isEmpty || !raw.startsWith('{')) {
      return null;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Map<String, dynamic>? _tryParseLegacyMapObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || !trimmed.contains('=')) {
      return null;
    }

    final body = _unwrapBracketPair(trimmed);
    final keyPattern = RegExp(r'([A-Za-z_][A-Za-z0-9_]*)\s*=');
    final keyMatches = keyPattern.allMatches(body).toList();
    if (keyMatches.isEmpty) {
      return null;
    }

    final parsed = <String, dynamic>{};
    for (int i = 0; i < keyMatches.length; i++) {
      final key = keyMatches[i].group(1)?.toLowerCase();
      if (key == null || key.isEmpty) {
        continue;
      }

      final int valueStart = keyMatches[i].end;
      final int valueEnd =
          i + 1 < keyMatches.length ? keyMatches[i + 1].start : body.length;
      if (valueStart >= valueEnd) {
        continue;
      }

      String value = body.substring(valueStart, valueEnd).trim();
      if (value.endsWith(',')) {
        value = value.substring(0, value.length - 1).trim();
      }
      value = _unwrapQuotedString(value);
      if (value.isNotEmpty) {
        parsed[key] = value;
      }
    }

    return parsed.isEmpty ? null : parsed;
  }

  String _sanitizeMapDestination(String destinationRaw) {
    final trimmed = destinationRaw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final legacy = _tryParseLegacyMapObject(trimmed);
    if (legacy != null) {
      final fromLegacy = _firstNonEmpty(
        legacy,
        const <String>['adr', 'address', 'destination', 'daddr', 'query'],
      );
      if (fromLegacy != null) {
        return fromLegacy.trim();
      }
    }

    final unwrapped = _unwrapBracketPair(trimmed);
    final lower = unwrapped.toLowerCase();
    for (final prefix in const <String>[
      'adr=',
      'address=',
      'destination=',
      'daddr=',
      'query='
    ]) {
      if (lower.startsWith(prefix)) {
        return _normalizeMapAddress(unwrapped.substring(prefix.length).trim());
      }
    }

    return _normalizeMapAddress(unwrapped);
  }

  String _unwrapBracketPair(String raw) {
    if (raw.length >= 2) {
      final startsWithBrace = raw.startsWith('{') && raw.endsWith('}');
      final startsWithBracket = raw.startsWith('[') && raw.endsWith(']');
      if (startsWithBrace || startsWithBracket) {
        return raw.substring(1, raw.length - 1).trim();
      }
    }
    return raw;
  }

  String _unwrapQuotedString(String raw) {
    if (raw.length >= 2) {
      if ((raw.startsWith('"') && raw.endsWith('"')) ||
          (raw.startsWith("'") && raw.endsWith("'"))) {
        return raw.substring(1, raw.length - 1).trim();
      }
    }
    return raw;
  }

  String _normalizeMapAddress(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final withoutCountryZip = trimmed.replaceFirst(
      RegExp(r'^\s*(台灣|台湾)\s*\d{3}\s*'),
      '',
    );
    if (withoutCountryZip.trim().isNotEmpty && withoutCountryZip != trimmed) {
      return withoutCountryZip.trim();
    }

    return trimmed;
  }

  String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Uri? _buildGoogleMapUriFromCoordinate(String source) {
    final coordinatePattern = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    );
    final match = coordinatePattern.firstMatch(source);
    if (match == null) {
      return null;
    }

    final latitude = match.group(1);
    final longitude = match.group(2);
    return _buildGoogleNavigationUri(destination: '$latitude,$longitude');
  }

  Uri _buildGoogleNavigationUri({
    required String destination,
    String? origin,
  }) {
    final query = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
      'dir_action': 'navigate',
    };
    final normalizedOrigin = origin?.trim();
    if (normalizedOrigin != null && normalizedOrigin.isNotEmpty) {
      query['origin'] = normalizedOrigin;
    }
    return Uri.https('www.google.com', '/maps/dir/', query);
  }

  Uri? _buildWebFallbackMapUri(Uri original) {
    final scheme = original.scheme.toLowerCase();
    if (scheme == 'https' || scheme == 'http') {
      return null;
    }

    String? destination;
    if (scheme == 'google.navigation') {
      destination = original.queryParameters['q'];
      if (destination == null || destination.trim().isEmpty) {
        final path = original.path.trim();
        if (path.startsWith('q=')) {
          destination = path.substring(2).trim();
        } else if (path.isNotEmpty) {
          destination = path;
        }
      }
    } else if (scheme == 'comgooglemaps' || scheme == 'geo') {
      destination = original.queryParameters['q'] ??
          original.queryParameters['daddr'] ??
          original.queryParameters['destination'];
    } else if (scheme == 'intent') {
      destination = original.queryParameters['q'] ??
          original.queryParameters['daddr'] ??
          original.queryParameters['destination'];
      destination ??=
          original.path.trim().isEmpty ? null : original.path.trim();
    }

    final trimmedDestination = destination?.trim();
    if (trimmedDestination == null || trimmedDestination.isEmpty) {
      return null;
    }
    return _buildGoogleNavigationUri(
      destination: _sanitizeMapDestination(trimmedDestination),
    );
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
