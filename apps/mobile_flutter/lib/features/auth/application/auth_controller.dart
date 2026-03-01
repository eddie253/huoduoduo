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
      ref: ref, authRepository: ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  final Ref ref;
  final AuthRepository authRepository;

  AuthController({required this.ref, required this.authRepository})
      : super(const AsyncData<AuthSession?>(null));

  Future<AuthSession> login(
      {required String account,
      required String password,
      required String platform}) async {
    state = const AsyncLoading<AuthSession?>();
    final deviceId = await _resolveDeviceId();
    final request = LoginRequest(
        account: account,
        password: password,
        deviceId: deviceId,
        platform: platform);
    try {
      final session = await authRepository.login(request);
      await ref.read(tokenStorageProvider).saveTokens(
          accessToken: session.accessToken, refreshToken: session.refreshToken);
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

  String _mapErrorCodeMessage(String code, {String? fallback}) {
    switch (code) {
      case 'LEGACY_TIMEOUT':
        return '系統連線逾時，請稍後再試。';
      case 'LEGACY_BAD_RESPONSE':
        return '系統服務暫時異常，請稍後再試。';
      case 'LEGACY_BUSINESS_ERROR':
        return fallback ?? '帳號或密碼錯誤，請重新輸入。';
      default:
        return fallback ?? '登入失敗，請稍後再試。';
    }
  }
}
