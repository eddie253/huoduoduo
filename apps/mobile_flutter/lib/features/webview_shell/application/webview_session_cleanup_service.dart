import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewSessionCleanupService {
  const WebviewSessionCleanupService();

  Future<void> clearWebSession({
    required List<String> domains,
    InAppWebViewController? controller,
  }) async {
    final cookieManager = CookieManager.instance();

    for (final domain in domains) {
      await cookieManager.deleteCookies(
        url: WebUri('https://$domain'),
        domain: domain,
      );
    }

    await WebStorageManager.instance().deleteAllData();
    await controller?.clearHistory();
    await InAppWebViewController.clearAllCache();
  }
}
