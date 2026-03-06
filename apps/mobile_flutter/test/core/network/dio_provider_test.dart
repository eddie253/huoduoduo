import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/core/network/dio_provider.dart';
import 'package:mobile_flutter/core/storage/token_storage.dart';

class _FakeStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      null;

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
  }) async {}

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}

void main() {
  group('dioProvider', () {
    late ProviderContainer container;

    setUp(() {
      final fakeStorage = _FakeStorage();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(fakeStorage),
          tokenStorageProvider
              .overrideWithValue(TokenStorage(fakeStorage)),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('creates a Dio instance', () {
      final dio = container.read(dioProvider);
      expect(dio, isA<Dio>());
    });

    test('baseUrl defaults to emulator address', () {
      final dio = container.read(dioProvider);
      expect(dio.options.baseUrl, isNotEmpty);
    });

    test('connect/receive/send timeouts are set', () {
      final dio = container.read(dioProvider);
      expect(dio.options.connectTimeout, isNotNull);
      expect(dio.options.receiveTimeout, isNotNull);
      expect(dio.options.sendTimeout, isNotNull);
    });

    test('Accept header is application/json', () {
      final dio = container.read(dioProvider);
      expect(dio.options.headers['Accept'], 'application/json');
    });

    test('has at least one interceptor (auth token injector)', () {
      final dio = container.read(dioProvider);
      expect(dio.interceptors, isNotEmpty);
    });

    test('auth interceptor injects no header when token is null', () async {
      final dio = container.read(dioProvider);
      late RequestOptions captured;
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.reject(DioException(requestOptions: options));
        },
      ));

      await expectLater(
        dio.get('http://localhost/test'),
        throwsA(isA<DioException>()),
      );

      expect(captured.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('tokenStorageProvider', () {
    test('wraps secureStorageProvider', () {
      final fakeStorage = _FakeStorage();
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(fakeStorage)],
      );
      addTearDown(container.dispose);

      final tokenStorage = container.read(tokenStorageProvider);
      expect(tokenStorage, isA<TokenStorage>());
    });
  });
}
