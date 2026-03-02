import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show InAppWebViewController;

import 'package:mobile_flutter/core/config/app_config.dart';
import 'package:mobile_flutter/core/network/dio_provider.dart';
import 'package:mobile_flutter/core/storage/token_storage.dart';
import 'package:mobile_flutter/features/auth/application/auth_controller.dart';
import 'package:mobile_flutter/features/auth/data/auth_repository.dart';
import 'package:mobile_flutter/features/auth/domain/auth_models.dart';
import 'package:mobile_flutter/features/webview_shell/application/webview_session_cleanup_service.dart';

void main() {
  test('login success saves tokens and updates state', () async {
    final fakeRepo = _FakeAuthRepository(
      loginHandler: (LoginRequest request) async {
        expect(request.account, 'A114851669');
        expect(request.password, 'secret');
        expect(request.deviceId, 'unsupported-platform-device');
        return _sessionFixture();
      },
    );
    final fakeTokenStorage = _FakeTokenStorage();
    final fakeCleanup = _FakeCleanupService();

    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(fakeRepo),
        tokenStorageProvider.overrideWithValue(fakeTokenStorage),
        webviewSessionCleanupServiceProvider.overrideWithValue(fakeCleanup),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);
    final session = await controller.login(
      account: 'A114851669',
      password: 'secret',
      platform: 'android',
    );

    expect(session.accessToken, 'at-1');
    expect(fakeTokenStorage.accessToken, 'at-1');
    expect(fakeTokenStorage.refreshToken, 'rt-1');
    expect(container.read(authControllerProvider).value, isNotNull);
  });

  test('login failure maps error code to user-facing message', () async {
    final fakeRepo = _FakeAuthRepository(
      loginHandler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 502,
            data: <String, dynamic>{'code': 'LEGACY_TIMEOUT'},
          ),
          type: DioExceptionType.badResponse,
        );
      },
    );

    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(fakeRepo),
        tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        webviewSessionCleanupServiceProvider
            .overrideWithValue(_FakeCleanupService()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);

    await expectLater(
      () => controller.login(
        account: 'A114851669',
        password: 'bad',
        platform: 'android',
      ),
      throwsA(
        isA<Exception>().having(
          (Exception error) => error.toString(),
          'message',
          contains('LEGACY_TIMEOUT: 系統連線逾時，請稍後再試。'),
        ),
      ),
    );

    expect(container.read(authControllerProvider).hasError, isTrue);
  });

  test('logout clears token and web session cleanup', () async {
    final fakeRepo = _FakeAuthRepository(
      loginHandler: (_) async => _sessionFixture(),
    );
    final fakeTokenStorage = _FakeTokenStorage()
      ..accessToken = 'at-1'
      ..refreshToken = 'rt-1';
    final fakeCleanup = _FakeCleanupService();

    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(fakeRepo),
        tokenStorageProvider.overrideWithValue(fakeTokenStorage),
        webviewSessionCleanupServiceProvider.overrideWithValue(fakeCleanup),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);
    await controller.logout();

    expect(fakeRepo.lastLogoutRefreshToken, 'rt-1');
    expect(fakeCleanup.called, isTrue);
    expect(fakeCleanup.lastDomains, AppConfig.allowedWebHosts);
    expect(fakeTokenStorage.cleared, isTrue);
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('logout still runs cleanup when refresh token is missing', () async {
    final fakeRepo = _FakeAuthRepository(
      loginHandler: (_) async => _sessionFixture(),
    );
    final fakeTokenStorage = _FakeTokenStorage();
    final fakeCleanup = _FakeCleanupService();

    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(fakeRepo),
        tokenStorageProvider.overrideWithValue(fakeTokenStorage),
        webviewSessionCleanupServiceProvider.overrideWithValue(fakeCleanup),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);
    await controller.logout();

    expect(fakeRepo.lastLogoutRefreshToken, isNull);
    expect(fakeCleanup.called, isTrue);
    expect(fakeTokenStorage.cleared, isTrue);
  });

  test('login failure with Dio message uses message fallback', () async {
    final fakeRepo = _FakeAuthRepository(
      loginHandler: (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          message: 'temporary network issue',
          type: DioExceptionType.connectionError,
        );
      },
    );

    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(fakeRepo),
        tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        webviewSessionCleanupServiceProvider
            .overrideWithValue(_FakeCleanupService()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);
    await expectLater(
      () => controller.login(
        account: 'A114851669',
        password: 'bad',
        platform: 'android',
      ),
      throwsA(
        isA<Exception>().having(
          (Exception error) => error.toString(),
          'message',
          contains('temporary network issue'),
        ),
      ),
    );
  });

  test('login failure with non-exception object maps to unknown error',
      () async {
    final fakeRepo = _FakeAuthRepository(
      loginHandler: (_) async => throw 'raw failure',
    );

    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(fakeRepo),
        tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        webviewSessionCleanupServiceProvider
            .overrideWithValue(_FakeCleanupService()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);
    await expectLater(
      () => controller.login(
        account: 'A114851669',
        password: 'bad',
        platform: 'android',
      ),
      throwsA(
        isA<Exception>().having(
          (Exception error) => error.toString(),
          'message',
          contains('Unknown error'),
        ),
      ),
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    required this.loginHandler,
  });

  final Future<AuthSession> Function(LoginRequest request) loginHandler;

  String? lastLogoutRefreshToken;

  @override
  Future<AuthSession> login(LoginRequest request) {
    return loginHandler(request);
  }

  @override
  Future<Map<String, String>> refresh(String refreshToken) async {
    return <String, String>{
      'accessToken': 'at-2',
      'refreshToken': 'rt-2',
    };
  }

  @override
  Future<void> logout(String? refreshToken) async {
    lastLogoutRefreshToken = refreshToken;
  }
}

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage() : super(const FlutterSecureStorage());

  String? accessToken;
  String? refreshToken;
  bool cleared = false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> clear() async {
    cleared = true;
    accessToken = null;
    refreshToken = null;
  }
}

class _FakeCleanupService extends WebviewSessionCleanupService {
  bool called = false;
  List<String>? lastDomains;

  @override
  Future<void> clearWebSession({
    required List<String> domains,
    InAppWebViewController? controller,
  }) async {
    called = true;
    lastDomains = domains;
  }
}

AuthSession _sessionFixture() {
  return const AuthSession(
    accessToken: 'at-1',
    refreshToken: 'rt-1',
    user: UserProfile(
      id: 'D001',
      contractNo: 'D001',
      name: 'Tester',
      role: 'driver',
    ),
    webviewBootstrap: WebviewBootstrap(
      baseUrl: 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1',
      registerUrl: 'https://old.huoduoduo.com.tw/register/register.aspx',
      resetPasswordUrl:
          'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
      cookies: <WebCookieModel>[
        WebCookieModel(
          name: 'Account',
          value: 'A114851669',
          domain: 'old.huoduoduo.com.tw',
          path: '/',
          secure: true,
          httpOnly: false,
        ),
      ],
    ),
  );
}
