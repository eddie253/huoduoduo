import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/auth/domain/auth_models.dart';

void main() {
  test('LoginRequest.toJson exports API payload fields', () {
    const request = LoginRequest(
      account: 'A114851669',
      password: 'secret',
      deviceId: 'device-1',
      platform: 'android',
    );

    expect(request.toJson(), <String, dynamic>{
      'account': 'A114851669',
      'password': 'secret',
      'deviceId': 'device-1',
      'platform': 'android',
    });
  });

  test('WebCookieModel.fromJson applies defaults for optional fields', () {
    final cookie = WebCookieModel.fromJson(<String, dynamic>{
      'name': 'Account',
      'value': 'A114851669',
      'domain': 'old.huoduoduo.com.tw',
    });

    expect(cookie.path, '/');
    expect(cookie.secure, isTrue);
    expect(cookie.httpOnly, isFalse);
  });

  test('WebviewBootstrap.fromJson filters invalid cookie entries', () {
    final bootstrap = WebviewBootstrap.fromJson(<String, dynamic>{
      'baseUrl': 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1',
      'registerUrl': 'https://old.huoduoduo.com.tw/register/register.aspx',
      'resetPasswordUrl':
          'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
      'cookies': <dynamic>[
        <String, dynamic>{
          'name': 'Account',
          'value': 'A114851669',
          'domain': 'old.huoduoduo.com.tw',
          'path': '/',
          'secure': true,
          'httpOnly': false,
        },
        'not-a-cookie-map',
      ],
    });

    expect(bootstrap.cookies, hasLength(1));
    expect(bootstrap.cookies.first.name, 'Account');
  });

  test('AuthSession.fromJson parses nested structures and fallbacks', () {
    final session = AuthSession.fromJson(<String, dynamic>{
      'accessToken': 'at-1',
      'refreshToken': 'rt-1',
      'user': <String, dynamic>{
        'id': 'D001',
        'contractNo': 'C001',
        'name': 'Tester',
        'role': 'driver',
      },
      'webviewBootstrap': <String, dynamic>{
        'baseUrl': 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1',
        'registerUrl': 'https://old.huoduoduo.com.tw/register/register.aspx',
        'resetPasswordUrl':
            'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
        'cookies': <dynamic>[
          <String, dynamic>{
            'name': 'Kind',
            'value': 'android',
            'domain': 'old.huoduoduo.com.tw',
            'path': '/',
            'secure': true,
            'httpOnly': false,
          }
        ],
      },
    });

    expect(session.accessToken, 'at-1');
    expect(session.user.contractNo, 'C001');
    expect(session.webviewBootstrap.cookies.first.name, 'Kind');

    final fallback = AuthSession.fromJson(<String, dynamic>{});
    expect(fallback.accessToken, isEmpty);
    expect(fallback.user.id, isEmpty);
    expect(fallback.webviewBootstrap.cookies, isEmpty);
  });
}
