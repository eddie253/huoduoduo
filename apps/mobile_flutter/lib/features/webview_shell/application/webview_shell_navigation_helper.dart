import '../../../core/config/app_config.dart';
import 'map_navigation_preflight_service.dart';

enum ExternalLaunchKind {
  none,
  external,
  map,
}

class ExternalLaunchDecision {
  const ExternalLaunchDecision._(this.kind);

  const ExternalLaunchDecision.none() : this._(ExternalLaunchKind.none);

  const ExternalLaunchDecision.external() : this._(ExternalLaunchKind.external);

  const ExternalLaunchDecision.map() : this._(ExternalLaunchKind.map);

  final ExternalLaunchKind kind;

  bool get shouldLaunchExternally => kind != ExternalLaunchKind.none;

  bool get requiresMapPreflight => kind == ExternalLaunchKind.map;
}

class WebviewShellNavigationHelper {
  WebviewShellNavigationHelper({
    Set<String>? allowedHosts,
    Set<String>? externalLaunchSchemes,
    Set<String>? externalMapHosts,
  })  : _allowedHosts = _normalizeSet(
          allowedHosts ?? AppConfig.allowedWebHosts.toSet(),
        ),
        _externalLaunchSchemes = _normalizeSet(
          externalLaunchSchemes ?? _defaultExternalLaunchSchemes,
        ),
        _externalMapHosts = _normalizeSet(
          externalMapHosts ?? _defaultExternalMapHosts,
        );

  static const String blockedNavigationMessage =
      'Blocked navigation to non-whitelisted domain.';
  static const String fallbackPreflightMessage = 'Navigation preflight failed.';

  static const Set<String> _defaultExternalLaunchSchemes = <String>{
    'tel',
    'geo',
    'google.navigation',
    'comgooglemaps',
    'intent',
    'sms',
    'mailto',
  };

  static const Set<String> _defaultExternalMapHosts = <String>{
    'www.google.com',
    'maps.google.com',
    'maps.app.goo.gl',
  };

  final Set<String> _allowedHosts;
  final Set<String> _externalLaunchSchemes;
  final Set<String> _externalMapHosts;

  bool isAllowedHost(String? host) {
    if (host == null || host.isEmpty) {
      return false;
    }
    return _allowedHosts.contains(host.toLowerCase());
  }

  Uri? normalizeAllowedHttpsUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }
    if (!isAllowedHost(uri.host)) {
      return null;
    }
    return uri;
  }

  ExternalLaunchDecision classifyExternalUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final bool isMapPathOnGoogle =
        host == 'www.google.com' && uri.path.toLowerCase().startsWith('/maps');

    final bool isWebMap = (scheme == 'https' || scheme == 'http') &&
        (_externalMapHosts.contains(host) || isMapPathOnGoogle);

    final bool shouldLaunch =
        _externalLaunchSchemes.contains(scheme) || isWebMap;
    if (!shouldLaunch) {
      return const ExternalLaunchDecision.none();
    }

    final bool isMapLaunch = scheme == 'geo' ||
        scheme == 'google.navigation' ||
        scheme == 'comgooglemaps' ||
        isWebMap;
    if (isMapLaunch) {
      return const ExternalLaunchDecision.map();
    }
    return const ExternalLaunchDecision.external();
  }

  String resolvePreflightError(MapNavigationPreflightResult preflight) {
    final message = preflight.message?.trim();
    if (message == null || message.isEmpty) {
      return fallbackPreflightMessage;
    }
    return message;
  }

  static Set<String> _normalizeSet(Set<String> values) {
    return values.map((value) => value.toLowerCase()).toSet();
  }
}
