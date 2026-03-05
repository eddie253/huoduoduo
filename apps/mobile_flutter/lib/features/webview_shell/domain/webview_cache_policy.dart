import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum WebviewRouteClass { session, transaction }

class WebviewCachePolicyResolver {
  const WebviewCachePolicyResolver();

  static const List<String> _transactionPathKeywords = <String>[
    '/app/rvt/',
    '/app/inq/',
    '/app/arv/',
    '/app/currency/',
    '/app/pxy/',
    '/shipment',
    '/delivery',
    '/exception',
    '/reservation',
  ];

  WebviewRouteClass classify(WebUri? uri) {
    if (uri == null) {
      return WebviewRouteClass.transaction;
    }

    final path = uri.path.toLowerCase();
    final fullUri = uri.toString().toLowerCase();
    for (final keyword in _transactionPathKeywords) {
      if (path.contains(keyword) || fullUri.contains(keyword)) {
        return WebviewRouteClass.transaction;
      }
    }
    return WebviewRouteClass.session;
  }

  URLRequestCachePolicy cachePolicyFor(WebUri? uri) {
    final routeClass = classify(uri);
    if (routeClass == WebviewRouteClass.transaction) {
      return URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA;
    }
    return URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY;
  }
}
