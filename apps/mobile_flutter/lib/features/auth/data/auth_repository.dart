import 'package:dio/dio.dart';
import '../domain/auth_models.dart';

abstract class AuthRepository {
  Future<AuthSession> login(LoginRequest request);
  Future<Map<String, String>> refresh(String refreshToken);
  Future<void> logout(String? refreshToken);
}

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl(this._dio);

  @override
  Future<AuthSession> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson()
    );
    final data = response.data ?? <String, dynamic>{};
    return AuthSession.fromJson(data);
  }

  @override
  Future<Map<String, String>> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken}
    );
    final data = response.data ?? <String, dynamic>{};
    return <String, String>{
      'accessToken': data['accessToken'] as String? ?? '',
      'refreshToken': data['refreshToken'] as String? ?? ''
    };
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: <String, dynamic>{'refreshToken': refreshToken}
    );
  }
}
