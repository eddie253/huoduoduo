// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/webview_shell/domain/webview_navigation_policy.dart';

void main() {
  test('forces reload for GET when policy requires no-cache', () {
    final bool shouldReload = WebviewNavigationPolicy.shouldForceReload(
      targetCachePolicy:
          URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      currentCachePolicy: URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      requestMethod: 'GET',
    );

    expect(shouldReload, isTrue);
  });

  test('forces reload for HEAD when policy requires no-cache', () {
    final bool shouldReload = WebviewNavigationPolicy.shouldForceReload(
      targetCachePolicy:
          URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      currentCachePolicy: URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      requestMethod: 'HEAD',
    );

    expect(shouldReload, isTrue);
  });

  test('does not force reload for POST to keep legacy postback flow', () {
    final bool shouldReload = WebviewNavigationPolicy.shouldForceReload(
      targetCachePolicy:
          URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      currentCachePolicy: URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      requestMethod: 'POST',
    );

    expect(shouldReload, isFalse);
  });

  test('does not force reload when target policy is not reload', () {
    final bool shouldReload = WebviewNavigationPolicy.shouldForceReload(
      targetCachePolicy: URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      currentCachePolicy: URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      requestMethod: 'GET',
    );

    expect(shouldReload, isFalse);
  });

  test('does not force reload when current policy already matches', () {
    final bool shouldReload = WebviewNavigationPolicy.shouldForceReload(
      targetCachePolicy:
          URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      currentCachePolicy:
          URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      requestMethod: 'GET',
    );

    expect(shouldReload, isFalse);
  });
}
