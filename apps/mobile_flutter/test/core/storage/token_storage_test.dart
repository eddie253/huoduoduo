import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_flutter/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String?> _store = {};

  setUp(() {
    _store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'write':
          _store[args!['key'] as String] = args['value'] as String?;
          return null;
        case 'read':
          return _store[args!['key'] as String];
        case 'delete':
          _store.remove(args!['key'] as String);
          return null;
        case 'deleteAll':
          _store.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  TokenStorage makeStorage() =>
      TokenStorage(const FlutterSecureStorage());

  group('TokenStorage.saveTokens', () {
    test('writes both access and refresh tokens', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');

      expect(_store['access_token'], 'at-1');
      expect(_store['refresh_token'], 'rt-1');
    });

    test('overwrites previously saved tokens', () async {
      final storage = makeStorage();
      await storage.saveTokens(accessToken: 'old-at', refreshToken: 'old-rt');
      await storage.saveTokens(accessToken: 'new-at', refreshToken: 'new-rt');

      expect(_store['access_token'], 'new-at');
      expect(_store['refresh_token'], 'new-rt');
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
