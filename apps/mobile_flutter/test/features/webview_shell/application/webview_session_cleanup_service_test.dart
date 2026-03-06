import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:mobile_flutter/features/webview_shell/application/webview_session_cleanup_service.dart';

import '../../../helpers/fake_inappwebview_platform.dart';

void main() {
  test('clearWebSession clears cookies, storage, and cache', () async {
    final cookiePort = _FakeCookieCleanupPort();
    final storagePort = _FakeWebStorageCleanupPort();
    final cachePort = _FakeWebCacheCleanupPort();
    final service = WebviewSessionCleanupService(
      cookieCleanupPort: cookiePort,
      webStorageCleanupPort: storagePort,
      webCacheCleanupPort: cachePort,
    );

    await service.clearWebSession(
      domains: <String>['old.huoduoduo.com.tw', 'app.elf.com.tw'],
    );

    expect(cookiePort.calls.length, 2);
    expect(
      cookiePort.calls,
      <String>[
        'old.huoduoduo.com.tw@https://old.huoduoduo.com.tw',
        'app.elf.com.tw@https://app.elf.com.tw',
      ],
    );
    expect(storagePort.deleted, isTrue);
    expect(cachePort.cleared, isTrue);
  });

  test('clearWebSession propagates cookie cleanup failures', () async {
    final cookiePort = _FakeCookieCleanupPort()..throwOnCall = true;
    final service = WebviewSessionCleanupService(
      cookieCleanupPort: cookiePort,
      webStorageCleanupPort: _FakeWebStorageCleanupPort(),
      webCacheCleanupPort: _FakeWebCacheCleanupPort(),
    );

    await expectLater(
      service.clearWebSession(domains: <String>['old.huoduoduo.com.tw']),
      throwsA(isA<StateError>()),
    );
  });

  test('clearWebSession with empty domains skips cookies but clears rest',
      () async {
    final cookiePort = _FakeCookieCleanupPort();
    final storagePort = _FakeWebStorageCleanupPort();
    final cachePort = _FakeWebCacheCleanupPort();
    final service = WebviewSessionCleanupService(
      cookieCleanupPort: cookiePort,
      webStorageCleanupPort: storagePort,
      webCacheCleanupPort: cachePort,
    );

    await service.clearWebSession(domains: <String>[]);

    expect(cookiePort.calls, isEmpty);
    expect(storagePort.deleted, isTrue);
    expect(cachePort.cleared, isTrue);
  });

  test('clearWebSession with single domain calls cookie cleanup once',
      () async {
    final cookiePort = _FakeCookieCleanupPort();
    final service = WebviewSessionCleanupService(
      cookieCleanupPort: cookiePort,
      webStorageCleanupPort: _FakeWebStorageCleanupPort(),
      webCacheCleanupPort: _FakeWebCacheCleanupPort(),
    );

    await service
        .clearWebSession(domains: <String>['reserve.huoduoduo.com.tw']);

    expect(cookiePort.calls.length, 1);
    expect(cookiePort.calls.first, contains('reserve.huoduoduo.com.tw'));
  });

  group('InApp port implementations', () {
    late FakeIAWPlatform platform;

    setUpAll(() {
      platform = FakeIAWPlatform();
      InAppWebViewPlatform.instance = platform;
    });

    setUp(() {
      platform.cookieManagerDelegate?.deleteCallCount = 0;
      platform.cookieManagerDelegate?.setCallCount = 0;
      platform.storageManagerDelegate?.deleteAllDataCallCount = 0;
    });

    test(
        'InAppCookieCleanupPort.deleteCookies delegates to CookieManager platform',
        () async {
      const port = InAppCookieCleanupPort();
      await port.deleteCookies(
        url: WebUri('https://example.com'),
        domain: 'example.com',
      );
      expect(platform.cookieManagerDelegate!.deleteCallCount, 1);
    });

    test(
        'InAppWebStorageCleanupPort.deleteAllData delegates to WebStorageManager platform',
        () async {
      const port = InAppWebStorageCleanupPort();
      await port.deleteAllData();
      expect(platform.storageManagerDelegate!.deleteAllDataCallCount, 1);
    });

    test(
        'InAppWebCacheCleanupPort.clearAllCache delegates to InAppWebViewController static',
        () async {
      const port = InAppWebCacheCleanupPort();
      await expectLater(port.clearAllCache(), completes);
    });

    test('clearWebSession with non-null controller calls clearHistory',
        () async {
      final fakeCtrl = FakePlatformController();
      final controller =
          InAppWebViewController.fromPlatform(platform: fakeCtrl);
      final service = WebviewSessionCleanupService(
        cookieCleanupPort: _FakeCookieCleanupPort(),
        webStorageCleanupPort: _FakeWebStorageCleanupPort(),
        webCacheCleanupPort: _FakeWebCacheCleanupPort(),
      );

      await service
          .clearWebSession(domains: <String>[], controller: controller);

      expect(fakeCtrl.clearHistoryCalled, isTrue);
    });
  });
}

class _FakeCookieCleanupPort implements CookieCleanupPort {
  final List<String> calls = <String>[];
  bool throwOnCall = false;

  @override
  Future<void> deleteCookies(
      {required WebUri url, required String domain}) async {
    if (throwOnCall) {
      throw StateError('cookie cleanup failed');
    }
    calls.add('$domain@${url.toString()}');
  }
}

class _FakeWebStorageCleanupPort implements WebStorageCleanupPort {
  bool deleted = false;

  @override
  Future<void> deleteAllData() async {
    deleted = true;
  }
}

class _FakeWebCacheCleanupPort implements WebCacheCleanupPort {
  bool cleared = false;

  @override
  Future<void> clearAllCache() async {
    cleared = true;
  }
}
