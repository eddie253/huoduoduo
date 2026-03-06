import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FakeIAWPlatform extends InAppWebViewPlatform {
  FakePlatformCookieManager? cookieManagerDelegate;
  FakePlatformWebStorageManager? storageManagerDelegate;

  @override
  PlatformCookieManager createPlatformCookieManager(
      PlatformCookieManagerCreationParams params) {
    cookieManagerDelegate ??= FakePlatformCookieManager(params);
    return cookieManagerDelegate!;
  }

  @override
  PlatformWebStorageManager createPlatformWebStorageManager(
      PlatformWebStorageManagerCreationParams params) {
    storageManagerDelegate ??= FakePlatformWebStorageManager(params);
    return storageManagerDelegate!;
  }

  @override
  PlatformInAppWebViewController
      createPlatformInAppWebViewControllerStatic() =>
          FakePlatformControllerStatic();

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
          PlatformInAppWebViewWidgetCreationParams params) =>
      FakePlatformWebViewWidget(params);
}

class FakePlatformCookieManager extends PlatformCookieManager {
  FakePlatformCookieManager(super.params) : super.implementation();

  int deleteCallCount = 0;
  int setCallCount = 0;

  @override
  Future<bool> deleteCookies({
    required WebUri url,
    String path = '/',
    String? domain,
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async {
    deleteCallCount++;
    return true;
  }

  @override
  Future<bool> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    int? expiresDate,
    int? maxAge,
    bool? isSecure,
    bool? isHttpOnly,
    HTTPCookieSameSitePolicy? sameSite,
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async {
    setCallCount++;
    return true;
  }

  @override
  Future<bool> deleteAllCookies() async => true;

  @override
  Future<List<Cookie>> getCookies({
    required WebUri url,
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async =>
      [];

  @override
  Future<bool> removeSessionCookies() async => true;

  @override
  Future<List<Cookie>> getAllCookies() async => [];
}

class FakePlatformWebStorageManager extends PlatformWebStorageManager {
  FakePlatformWebStorageManager(super.params) : super.implementation();

  int deleteAllDataCallCount = 0;

  @override
  Future<void> deleteAllData() async {
    deleteAllDataCallCount++;
  }
}

class FakePlatformControllerStatic extends PlatformInAppWebViewController {
  FakePlatformControllerStatic()
      : super.implementation(
            const PlatformInAppWebViewControllerCreationParams(id: '_static'));

  int clearAllCacheCallCount = 0;

  @override
  Future<void> clearAllCache({bool includeDiskFiles = true}) async {
    clearAllCacheCallCount++;
  }

  @override
  void dispose({bool isKeepAlive = false}) {}
}

class FakePlatformController extends PlatformInAppWebViewController {
  FakePlatformController()
      : super.implementation(
            const PlatformInAppWebViewControllerCreationParams(id: '_ctrl'));

  bool clearHistoryCalled = false;

  @override
  Future<void> clearHistory() async {
    clearHistoryCalled = true;
  }

  @override
  void dispose({bool isKeepAlive = false}) {}
}

class FakePlatformWebViewWidget extends PlatformInAppWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}
