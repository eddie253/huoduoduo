import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../webview_shell/application/webview_session_cleanup_service.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(dioProvider));
});

final webviewSessionCleanupServiceProvider =
    Provider<WebviewSessionCleanupService>((ref) {
  return const WebviewSessionCleanupService();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController({
    required this.ref,
    required this.authRepository,
  }) : super(const AsyncData<AuthSession?>(null));

  final Ref ref;
  final AuthRepository authRepository;

  Future<AuthSession> login({
    required String account,
    required String password,
    required String platform,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    final deviceId = await _resolveDeviceId();
    final request = LoginRequest(
      account: account,
      password: password,
      deviceId: deviceId,
      platform: platform,
    );

    try {
      final session = await authRepository.login(request);
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
      state = AsyncData<AuthSession?>(session);
      return session;
    } catch (error, stackTrace) {
      final mapped = _toDisplayError(error);
      state = AsyncError<AuthSession?>(mapped, stackTrace);
      throw mapped;
    }
  }

  Future<void> logout() async {
    final refreshToken =
        await ref.read(tokenStorageProvider).readRefreshToken();
    await authRepository.logout(refreshToken);
    await ref
        .read(webviewSessionCleanupServiceProvider)
        .clearWebSession(domains: AppConfig.allowedWebHosts);
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData<AuthSession?>(null);
  }

  Future<String> _resolveDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfoPlugin.androidInfo;
      return info.id;
    }
    if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      return info.identifierForVendor ?? 'ios-unknown-device';
    }
    return 'unsupported-platform-device';
  }

  Exception _toDisplayError(Object error) {
    if (error is DioException) {
      if (_isConnectionTimeout(error)) {
        return Exception(_timeoutHintMessage());
      }
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Exception('服務回應逾時，請稍後再試。');
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final code = data['code']?.toString();
        final message = data['message']?.toString();
        if (code != null) {
          final mapped = _mapErrorCodeMessage(code, fallback: message);
          return Exception('$code: $mapped');
        }
        if (message != null) {
          return Exception(message);
        }
      }
      return Exception(error.message ?? 'Network error');
    }

    if (error is Exception) {
      return error;
    }
    return Exception('Unknown error');
  }

  bool _isConnectionTimeout(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    if (error.type != DioExceptionType.connectionError) {
      return false;
    }
    final raw = (error.message ?? '').toLowerCase();
    return raw.contains('timeout') || raw.contains('timed out');
  }

  String _timeoutHintMessage() {
    const baseUrl = AppConfig.apiBaseUrl;
    if (baseUrl.contains('10.0.2.2')) {
      return '連線逾時，請確認 API 服務已啟動。若使用實機，請將 API_BASE_URL 改成電腦區網 IP（例如 http://192.168.x.x:3000/v1）。';
    }
    return '連線逾時，請確認伺服器可連線後再試。';
  }

  String _mapErrorCodeMessage(String code, {String? fallback}) {
    switch (code) {
      case 'LEGACY_TIMEOUT':
        return '舊系統連線逾時，請稍後再試。';
      case 'LEGACY_BAD_RESPONSE':
        return '舊系統回傳資料格式異常，請稍後再試。';
      case 'LEGACY_BUSINESS_ERROR':
        return fallback ?? '系統回傳業務錯誤，請確認資料後重試。';
      default:
        return fallback ?? '登入失敗，請稍後再試。';
    }
  }
}
