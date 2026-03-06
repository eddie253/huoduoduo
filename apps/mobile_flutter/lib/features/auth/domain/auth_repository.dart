import 'auth_models.dart';

abstract class AuthRepository {
  Future<AuthSession> login(LoginRequest request);
  Future<Map<String, String>> refresh(String refreshToken);
  Future<void> logout(String? refreshToken);
}
