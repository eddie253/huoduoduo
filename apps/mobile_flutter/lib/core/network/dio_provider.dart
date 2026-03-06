import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../../features/auth/application/auth_event_bus.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

Dio _buildDio({
  required TokenStorage tokenStorage,
  required Duration connectTimeout,
  required Duration receiveTimeout,
  required Duration sendTimeout,
}) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
    headers: <String, String>{'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
      } on StateError {
        // During teardown a ProviderContainer may already be disposed.
      }
      handler.next(options);
    },
  ));

  dio.interceptors
      .add(_RefreshInterceptor(dio: dio, tokenStorage: tokenStorage));

  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  return _buildDio(
    tokenStorage: ref.watch(tokenStorageProvider),
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    sendTimeout: const Duration(seconds: 8),
  );
});

final uploadDioProvider = Provider<Dio>((ref) {
  final dio = _buildDio(
    tokenStorage: ref.watch(tokenStorageProvider),
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
  );
  dio.interceptors.add(_RetryInterceptor(dio: dio));
  return dio;
});

class _RefreshInterceptor extends Interceptor {
  _RefreshInterceptor({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _queue = [];

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _queue.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('no refresh token');
      }
      final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: <String, dynamic>{'refreshToken': refreshToken});
      final data = response.data ?? <String, dynamic>{};
      final newAccess = data['accessToken'] as String? ?? '';
      final newRefresh = data['refreshToken'] as String? ?? '';
      if (newAccess.isEmpty) throw Exception('empty access token');
      await tokenStorage.saveTokens(
          accessToken: newAccess, refreshToken: newRefresh);

      for (final pending in List<
          ({
            RequestOptions options,
            ErrorInterceptorHandler handler
          })>.of(_queue)) {
        pending.options.headers['Authorization'] = 'Bearer $newAccess';
        pending.options.extra['_retried'] = true;
        try {
          final retried = await dio.fetch<dynamic>(pending.options);
          pending.handler.resolve(retried);
        } catch (_) {
          pending.handler.next(DioException(requestOptions: pending.options));
        }
      }
      _queue.clear();

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      err.requestOptions.extra['_retried'] = true;
      final retried = await dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retried);
    } catch (_) {
      for (final pending in List<
          ({
            RequestOptions options,
            ErrorInterceptorHandler handler
          })>.of(_queue)) {
        pending.handler.next(DioException(requestOptions: pending.options));
      }
      _queue.clear();
      AuthEventBus.instance.emit(AuthEvent.sessionExpired);
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor({required this.dio});

  static const int _retries = 2;
  static const List<Duration> _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  final Dio dio;

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final attempt = err.requestOptions.extra['_retryAttempt'] as int? ?? 0;
    if (!_shouldRetry(err) || attempt >= _retries) {
      handler.next(err);
      return;
    }
    final delay = attempt < _retryDelays.length
        ? _retryDelays[attempt]
        : _retryDelays.last;
    await Future<void>.delayed(delay);
    err.requestOptions.extra['_retryAttempt'] = attempt + 1;
    try {
      final retried = await dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retried);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    final status = err.response?.statusCode ?? 0;
    return err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionTimeout ||
        status >= 500;
  }
}
