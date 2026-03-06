import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/webview_shell/domain/webview_cache_policy.dart';

void main() {
  const resolver = WebviewCachePolicyResolver();

  test('classifies transaction routes to no-cache policy', () {
    final uri = WebUri('https://app.elf.com.tw/cn/shipment/delivery');
    expect(resolver.classify(uri), WebviewRouteClass.transaction);
    expect(
      resolver.cachePolicyFor(uri),
      URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
    );
  });

  test('classifies legacy app routes to no-cache policy', () {
    final uri = WebUri('https://old.huoduoduo.com.tw/app/rvt/ge.aspx');
    expect(resolver.classify(uri), WebviewRouteClass.transaction);
    expect(
      resolver.cachePolicyFor(uri),
      URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
    );
  });

  test('classifies non-transaction routes to protocol cache policy', () {
    final uri = WebUri('https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1');
    expect(resolver.classify(uri), WebviewRouteClass.session);
    expect(
      resolver.cachePolicyFor(uri),
      URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
    );
  });
}
