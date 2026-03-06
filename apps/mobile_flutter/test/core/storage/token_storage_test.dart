import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_flutter/core/storage/token_storage.dart';

class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String?> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

void main() {
  late _FakeStorage fakeStorage;

  setUp(() {
    fakeStorage = _FakeStorage();
  });

  TokenStorage makeStorage() => TokenStorage(fakeStorage);

  group('TokenStorage.saveTokens', () {
    test('writes both access and refresh tokens', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');

      expect(await storage.readAccessToken(), 'at-1');
      expect(await storage.readRefreshToken(), 'rt-1');
    });

    test('overwrites previously saved tokens', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'old-at', refreshToken: 'old-rt');
      await storage.saveTokens(accessToken: 'new-at', refreshToken: 'new-rt');

      expect(await storage.readAccessToken(), 'new-at');
      expect(await storage.readRefreshToken(), 'new-rt');
    });
  });

  group('TokenStorage.readAccessToken', () {
    test('returns null when nothing saved', () async {
      final storage = makeStorage();
      expect(await storage.readAccessToken(), isNull);
    });

    test('returns saved access token', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'at-abc', refreshToken: 'rt-abc');
      expect(await storage.readAccessToken(), 'at-abc');
    });
  });

  group('TokenStorage.readRefreshToken', () {
    test('returns null when nothing saved', () async {
      final storage = makeStorage();
      expect(await storage.readRefreshToken(), isNull);
    });

    test('returns saved refresh token', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'at-xyz', refreshToken: 'rt-xyz');
      expect(await storage.readRefreshToken(), 'rt-xyz');
    });
  });

  group('TokenStorage.clear', () {
    test('removes all stored tokens', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');

      await storage.clear();

      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    });

    test('clear on empty store does not throw', () async {
      final storage = makeStorage();
      await expectLater(storage.clear(), completes);
    });
  });
}
