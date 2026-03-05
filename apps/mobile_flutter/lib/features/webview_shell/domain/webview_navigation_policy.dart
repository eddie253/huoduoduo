import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewNavigationPolicy {
  const WebviewNavigationPolicy._();

  static bool shouldForceReload({
    required URLRequestCachePolicy targetCachePolicy,
    required URLRequestCachePolicy? currentCachePolicy,
    required String? requestMethod,
  }) {
    if (targetCachePolicy !=
        URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA) {
      return false;
    }
    if (currentCachePolicy == targetCachePolicy) {
      return false;
    }
    final String normalizedMethod = (requestMethod ?? 'GET').toUpperCase();
    return normalizedMethod == 'GET' || normalizedMethod == 'HEAD';
  }
}
