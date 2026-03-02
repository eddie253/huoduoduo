import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class CookieCleanupPort {
  Future<void> deleteCookies({required WebUri url, required String domain});
}

class InAppCookieCleanupPort implements CookieCleanupPort {
  const InAppCookieCleanupPort();

  @override
  Future<void> deleteCookies({required WebUri url, required String domain}) {
    return CookieManager.instance().deleteCookies(url: url, domain: domain);
  }
}

abstract class WebStorageCleanupPort {
  Future<void> deleteAllData();
}

class InAppWebStorageCleanupPort implements WebStorageCleanupPort {
  const InAppWebStorageCleanupPort();

  @override
  Future<void> deleteAllData() {
    return WebStorageManager.instance().deleteAllData();
  }
}

abstract class WebCacheCleanupPort {
  Future<void> clearAllCache();
}

class InAppWebCacheCleanupPort implements WebCacheCleanupPort {
  const InAppWebCacheCleanupPort();

  @override
  Future<void> clearAllCache() {
    return InAppWebViewController.clearAllCache();
  }
}

class WebviewSessionCleanupService {
  const WebviewSessionCleanupService({
    this.cookieCleanupPort = const InAppCookieCleanupPort(),
    this.webStorageCleanupPort = const InAppWebStorageCleanupPort(),
    this.webCacheCleanupPort = const InAppWebCacheCleanupPort(),
  });

  final CookieCleanupPort cookieCleanupPort;
  final WebStorageCleanupPort webStorageCleanupPort;
  final WebCacheCleanupPort webCacheCleanupPort;

  Future<void> clearWebSession({
    required List<String> domains,
    InAppWebViewController? controller,
  }) async {
    for (final domain in domains) {
      await cookieCleanupPort.deleteCookies(
        url: WebUri('https://$domain'),
        domain: domain,
      );
    }

    await webStorageCleanupPort.deleteAllData();
    await controller?.clearHistory();
    await webCacheCleanupPort.clearAllCache();
  }
}
