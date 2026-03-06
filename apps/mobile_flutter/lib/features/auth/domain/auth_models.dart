class LoginRequest {
  final String account;
  final String password;
  final String deviceId;
  final String platform;

  const LoginRequest(
      {required this.account,
      required this.password,
      required this.deviceId,
      required this.platform});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'account': account,
      'password': password,
      'deviceId': deviceId,
      'platform': platform
    };
  }
}

class WebCookieModel {
  final String name;
  final String value;
  final String domain;
  final String path;
  final bool secure;
  final bool httpOnly;

  const WebCookieModel(
      {required this.name,
      required this.value,
      required this.domain,
      required this.path,
      required this.secure,
      required this.httpOnly});

  factory WebCookieModel.fromJson(Map<String, dynamic> json) {
    return WebCookieModel(
        name: json['name'] as String? ?? '',
        value: json['value'] as String? ?? '',
        domain: json['domain'] as String? ?? '',
        path: json['path'] as String? ?? '/',
        secure: json['secure'] as bool? ?? true,
        httpOnly: json['httpOnly'] as bool? ?? false);
  }
}

class WebviewBootstrap {
  final String baseUrl;
  final String registerUrl;
  final String resetPasswordUrl;
  final List<WebCookieModel> cookies;

  const WebviewBootstrap(
      {required this.baseUrl,
      required this.registerUrl,
      required this.resetPasswordUrl,
      required this.cookies});

  factory WebviewBootstrap.fromJson(Map<String, dynamic> json) {
    final dynamic cookiesJson = json['cookies'];
    return WebviewBootstrap(
        baseUrl: json['baseUrl'] as String? ?? '',
        registerUrl: json['registerUrl'] as String? ?? '',
        resetPasswordUrl: json['resetPasswordUrl'] as String? ?? '',
        cookies: (cookiesJson is List<dynamic> ? cookiesJson : <dynamic>[])
            .map((dynamic item) {
              if (item is Map) {
                return WebCookieModel.fromJson(item.cast<String, dynamic>());
              }
              return null;
            })
            .whereType<WebCookieModel>()
            .toList());
  }
}

class UserProfile {
  final String id;
  final String contractNo;
  final String name;
  final String role;

  const UserProfile(
      {required this.id,
      required this.contractNo,
      required this.name,
      required this.role});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
        id: json['id'] as String? ?? '',
        contractNo: json['contractNo'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '');
  }
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;
  final WebviewBootstrap webviewBootstrap;

  const AuthSession(
      {required this.accessToken,
      required this.refreshToken,
      required this.user,
      required this.webviewBootstrap});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'accessToken': final String accessToken,
        'refreshToken': final String refreshToken,
        'user': final Map userMap,
        'webviewBootstrap': final Map bootstrapMap,
      } =>
        AuthSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: UserProfile.fromJson(userMap.cast<String, dynamic>()),
          webviewBootstrap:
              WebviewBootstrap.fromJson(bootstrapMap.cast<String, dynamic>()),
        ),
      _ => throw const FormatException('AuthSession: missing required field'),
    };
  }
}
