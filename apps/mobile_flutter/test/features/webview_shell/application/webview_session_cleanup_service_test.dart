import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:mobile_flutter/features/webview_shell/application/webview_session_cleanup_service.dart';

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
}

class _FakeCookieCleanupPort implements CookieCleanupPort {
  final List<String> calls = <String>[];
  bool throwOnCall = false;

  @override
  Future<void> deleteCookies({required WebUri url, required String domain}) async {
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
