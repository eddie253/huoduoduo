import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/auth/data/auth_repository.dart';
import 'package:mobile_flutter/features/auth/domain/auth_models.dart';

import '../../../test_helpers/recording_dio_adapter.dart';

void main() {
  test('login posts payload and parses auth session', () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/auth/login');
      expect(options.method, 'POST');
      expect(options.data, <String, dynamic>{
        'account': 'A114851669',
        'password': 'secret',
        'deviceId': 'device-1',
        'platform': 'android',
      });
      return jsonBody(<String, dynamic>{
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
          'cookies': <dynamic>[],
        },
      });
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = AuthRepositoryImpl(dio);

    final session = await repository.login(
      const LoginRequest(
        account: 'A114851669',
        password: 'secret',
        deviceId: 'device-1',
        platform: 'android',
      ),
    );

    expect(session.accessToken, 'at-1');
    expect(session.user.id, 'D001');
  });

  test('refresh posts refresh token and returns normalized tokens', () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/auth/refresh');
      expect(options.method, 'POST');
      expect(options.data, <String, dynamic>{'refreshToken': 'rt-1'});
      return jsonBody(<String, dynamic>{
        'accessToken': 'at-2',
        'refreshToken': 'rt-2',
      });
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = AuthRepositoryImpl(dio);

    final tokens = await repository.refresh('rt-1');
    expect(tokens['accessToken'], 'at-2');
    expect(tokens['refreshToken'], 'rt-2');
  });

  test('logout posts refresh token, including null value', () async {
    final adapter = RecordingDioAdapter(responder: (RequestOptions options) {
      expect(options.path, '/auth/logout');
      expect(options.method, 'POST');
      expect(options.data, <String, dynamic>{'refreshToken': null});
      return jsonBody(<String, dynamic>{});
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = AuthRepositoryImpl(dio);

    await repository.logout(null);
    expect(adapter.requests, hasLength(1));
  });
}
