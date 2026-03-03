import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: <String, String>{'Accept': 'application/json'}));

  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    try {
      final accessToken =
          await ref.read(tokenStorageProvider).readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } on StateError {
      // During teardown a ProviderContainer may already be disposed.
      // Skip auth header injection instead of crashing async requests.
    }
    handler.next(options);
  }));

  return dio;
});
