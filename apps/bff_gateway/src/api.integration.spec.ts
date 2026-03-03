import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
// eslint-disable-next-line @typescript-eslint/no-require-imports
import request = require('supertest');
import { AppModule } from './app.module';
import { LegacySoapClient, LegacyUser, WebCookieModel } from './adapters/soap/legacy-soap.client';
import { LegacySoapError } from './adapters/soap/legacy-soap.error';
import { RedisTokenStoreService, RefreshTokenState } from './security/redis-token-store.service';
import { LegacySoapExceptionFilter } from './security/legacy-soap-exception.filter';

class TestTokenStore {
  private readonly values = new Map<string, RefreshTokenState>();
  private idx = 0;

  async ensureReady(): Promise<void> {}

  async issueToken(state: RefreshTokenState, _ttlSeconds: number): Promise<string> {
    const token = `rt-${++this.idx}`;
    this.values.set(token, state);
    return token;
  }

  async consumeToken(token: string): Promise<RefreshTokenState | null> {
    const value = this.values.get(token) ?? null;
    this.values.delete(token);
    return value;
  }

  async revokeToken(token: string): Promise<boolean> {
    return this.values.delete(token);
  }
}

describe('API integration', () => {
  let app: INestApplication;
  let mockLegacySoapClient: Partial<LegacySoapClient>;
  let sharedAccessToken = '';
  const submitShipmentDelivery = jest.fn();
  const assertNoStoreHeaders = (result: { headers: Record<string, string> }): void => {
    expect(result.headers['cache-control']).toBe('no-store, no-cache, must-revalidate');
    expect(result.headers.pragma).toBe('no-cache');
    expect(result.headers.expires).toBe('0');
  };

  beforeAll(async () => {
    mockLegacySoapClient = {
      validateLogin: jest.fn(async (account: string) => {
        if (account === 'bad_user') {
          return null;
        }
        return {
          id: 'D001',
          contractNo: 'D001',
          account,
          displayName: 'Tester',
          role: 'driver'
        } satisfies LegacyUser;
      }),
      buildWebviewCookies: jest.fn(async (account: string, identify: string) => {
        return [
          {
            name: 'Account',
            value: account,
            domain: 'old.huoduoduo.com.tw',
            path: '/',
            secure: true,
            httpOnly: false
          },
          {
            name: 'Identify',
            value: identify,
            domain: 'old.huoduoduo.com.tw',
            path: '/',
            secure: true,
            httpOnly: false
          },
          {
            name: 'Kind',
            value: 'android',
            domain: 'old.huoduoduo.com.tw',
            path: '/',
            secure: true,
            httpOnly: false
          }
        ] satisfies WebCookieModel[];
      }),
      getBulletins: jest.fn(async () => [
        {
          uid: '1',
          title: '系統公告測試',
          date: '2026-03-02T00:00:00Z'
        }
      ]),
      getShipment: jest.fn(async () => ({
        trackingNo: 'T1',
        recipient: 'A',
        address: 'B',
        phone: '',
        mobile: '',
        zipCode: '',
        city: '',
        district: '',
        status: 'PENDING',
        signedAt: null,
        signedImageFileName: null,
        signedLocation: null
      })),
      submitShipmentDelivery: submitShipmentDelivery.mockResolvedValue(undefined),
      submitShipmentException: jest.fn(async () => undefined),
      listReservations: jest.fn(async () => []),
      createReservation: jest.fn(async () => ({ reservationNo: 'R1', mode: 'standard' as const })),
      deleteReservation: jest.fn(async () => undefined),
      updateRegId: jest.fn(async () => undefined)
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule]
    })
      .overrideProvider(LegacySoapClient)
      .useValue(mockLegacySoapClient)
      .overrideProvider(RedisTokenStoreService)
      .useValue(new TestTokenStore())
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true
      })
    );
    app.useGlobalFilters(new LegacySoapExceptionFilter());
    await app.init();

    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'shared_token_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });
    expect(login.status).toBe(200);
    sharedAccessToken = String(login.body.accessToken);
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('POST /auth/login returns token on success and 401 on bad user', async () => {
    const ok = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'good_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });
    expect(ok.status).toBe(200);
    expect(ok.body.accessToken).toBeDefined();
    expect(ok.body.refreshToken).toBeDefined();
    assertNoStoreHeaders(ok as unknown as { headers: Record<string, string> });

    const bad = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'bad_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });
    expect(bad.status).toBe(401);
    assertNoStoreHeaders(bad as unknown as { headers: Record<string, string> });
  });

  it('POST /auth/refresh returns 200 and rotates token', async () => {
    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'refresh_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const refresh = await request(app.getHttpServer()).post('/v1/auth/refresh').send({
      refreshToken: login.body.refreshToken
    });

    expect(refresh.status).toBe(200);
    expect(refresh.body.accessToken).toBeDefined();
    expect(refresh.body.refreshToken).toBeDefined();
    expect(refresh.body.refreshToken).not.toBe(login.body.refreshToken);
    assertNoStoreHeaders(refresh as unknown as { headers: Record<string, string> });
  });

  it('P1_LOGIN_REQUEST_MAXLEN_VALIDATION returns 400 when request field exceeds maxLength', async () => {
    const tooLongAccount = `A${'1'.repeat(64)}`;
    const response = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: tooLongAccount,
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    expect(response.status).toBe(400);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('GET /bootstrap/webview returns cookies payload', async () => {
    const result = await request(app.getHttpServer())
      .get('/v1/bootstrap/webview')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(result.status).toBe(200);
    expect(result.body.baseUrl).toBeDefined();
    expect(Array.isArray(result.body.cookies)).toBe(true);
    expect(result.body.cookies.length).toBeGreaterThanOrEqual(3);
    assertNoStoreHeaders(result as unknown as { headers: Record<string, string> });
  });

  it('GET /bootstrap/webview returns 401 when missing authorization', async () => {
    const result = await request(app.getHttpServer()).get('/v1/bootstrap/webview');
    expect(result.status).toBe(401);
    expect(result.body.code).toBe('UNAUTHORIZED');
    assertNoStoreHeaders(result as unknown as { headers: Record<string, string> });
  });

  it('GET /bootstrap/bulletin returns current announcement', async () => {
    const result = await request(app.getHttpServer())
      .get('/v1/bootstrap/bulletin')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(result.status).toBe(200);
    expect(result.body.message).toBe('系統公告測試');
    expect(result.body.hasAnnouncement).toBe(true);
    assertNoStoreHeaders(result as unknown as { headers: Record<string, string> });
  });

  it('P1_REFRESH_LOGOUT_TOKEN_MAXLEN_VALIDATION returns 400 when refresh token is too long', async () => {
    const tooLongRefreshToken = `rt-${'x'.repeat(1022)}`;

    const refresh = await request(app.getHttpServer()).post('/v1/auth/refresh').send({
      refreshToken: tooLongRefreshToken
    });
    expect(refresh.status).toBe(400);

    const logout = await request(app.getHttpServer())
      .post('/v1/auth/logout')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        refreshToken: tooLongRefreshToken
      });

    expect(logout.status).toBe(400);
    assertNoStoreHeaders(logout as unknown as { headers: Record<string, string> });
  });

  it('P1_PUSH_REGISTER_REQUEST_MAXLEN_VALIDATION returns 400 when push request fields are too long', async () => {
    const response = await request(app.getHttpServer())
      .post('/v1/push/register')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        deviceId: `D${'1'.repeat(64)}`,
        platform: 'android',
        fcmToken: 'fcm-token-1',
        appVersion: 1
      });

    expect(response.status).toBe(400);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P1_LOGIN_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized critical fields', async () => {
    (mockLegacySoapClient.validateLogin as jest.Mock).mockResolvedValueOnce({
      id: `D${'1'.repeat(64)}`,
      contractNo: `C${'2'.repeat(64)}`,
      account: 'oversized_login_user',
      displayName: 'Tester',
      role: 'driver'
    } satisfies LegacyUser);

    const response = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'oversized_login_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P1_LOGIN_NAME_TRUNCATION truncates display name to 128 characters', async () => {
    const oversizedName = 'N'.repeat(256);
    (mockLegacySoapClient.validateLogin as jest.Mock).mockResolvedValueOnce({
      id: 'D001',
      contractNo: 'D001',
      account: 'truncate_name_user',
      displayName: oversizedName,
      role: 'driver'
    } satisfies LegacyUser);

    const response = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'truncate_name_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    expect(response.status).toBe(200);
    expect(typeof response.body.user.name).toBe('string');
    expect(response.body.user.name.length).toBe(128);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P1_BULLETIN_MESSAGE_TRUNCATION truncates bulletin message to 2000 characters', async () => {
    (mockLegacySoapClient.getBulletins as jest.Mock).mockResolvedValueOnce([
      {
        uid: '1',
        title: 'B'.repeat(2400),
        date: '2026-03-02T00:00:00Z'
      }
    ]);

    const response = await request(app.getHttpServer())
      .get('/v1/bootstrap/bulletin')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(200);
    expect(response.body.message.length).toBe(2000);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P1_BULLETIN_UPDATEDAT_REJECT rejects invalid updatedAt format', async () => {
    (mockLegacySoapClient.getBulletins as jest.Mock).mockResolvedValueOnce([
      {
        uid: '1',
        title: 'system bulletin',
        date: 'not-a-datetime'
      }
    ]);

    const response = await request(app.getHttpServer())
      .get('/v1/bootstrap/bulletin')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P2_SHIPMENT_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized shipment fields', async () => {
    (mockLegacySoapClient.getShipment as jest.Mock).mockResolvedValueOnce({
      trackingNo: 'T001',
      recipient: 'R'.repeat(130),
      address: 'A',
      phone: '',
      mobile: '',
      zipCode: '',
      city: '',
      district: '',
      status: 'PENDING',
      signedAt: null,
      signedImageFileName: null,
      signedLocation: null
    });

    const response = await request(app.getHttpServer())
      .get('/v1/shipments/T001')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P2_DELIVERY_EXCEPTION_REQUEST_MAXLEN_VALIDATION returns 400 on over-length request fields', async () => {
    const delivery = await request(app.getHttpServer())
      .post('/v1/shipments/T001/delivery')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        imageBase64: 'abc',
        imageFileName: `F${'x'.repeat(255)}`,
        latitude: '25.03',
        longitude: '121.56'
      });

    expect(delivery.status).toBe(400);
    assertNoStoreHeaders(delivery as unknown as { headers: Record<string, string> });

    const exception = await request(app.getHttpServer())
      .post('/v1/shipments/T001/exception')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        imageBase64: 'abc',
        imageFileName: 'proof.jpg',
        reasonCode: `R${'x'.repeat(64)}`,
        latitude: '25.03',
        longitude: '121.56'
      });

    expect(exception.status).toBe(400);
    assertNoStoreHeaders(exception as unknown as { headers: Record<string, string> });
  });

  it('POST /shipments/{id}/delivery forwards payload to legacy client', async () => {
    const payload = {
      imageBase64: 'abc',
      imageFileName: 'proof.jpg',
      latitude: '25.03',
      longitude: '121.56'
    };

    const response = await request(app.getHttpServer())
      .post('/v1/shipments/T001/delivery')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send(payload);

    expect(response.status).toBe(200);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
    expect(submitShipmentDelivery).toHaveBeenCalledWith(
      'T001',
      expect.objectContaining({
        imageBase64: 'abc',
        imageFileName: 'proof.jpg'
      })
    );
  });

  it('GET /shipments/{id} returns no-store headers', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/shipments/T001')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(200);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('GET /reservations returns no-store headers', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/reservations?mode=standard')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(200);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P3_RESERVATION_LIST_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized reservation fields', async () => {
    (mockLegacySoapClient.listReservations as jest.Mock).mockResolvedValueOnce([
      {
        reservationNo: 'R001',
        address: 'A'.repeat(513),
        fee: null,
        shipmentNos: ['T001'],
        mode: 'standard'
      }
    ]);

    const response = await request(app.getHttpServer())
      .get('/v1/reservations?mode=standard')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P3_CREATE_DELETE_REQUEST_MAXLEN_VALIDATION returns 400 on over-length request fields', async () => {
    const createTooLongAddress = await request(app.getHttpServer())
      .post('/v1/reservations?mode=standard')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        address: 'A'.repeat(513),
        shipmentNos: ['T001']
      });
    expect(createTooLongAddress.status).toBe(400);
    assertNoStoreHeaders(createTooLongAddress as unknown as { headers: Record<string, string> });

    const createTooManyNos = await request(app.getHttpServer())
      .post('/v1/reservations?mode=standard')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        address: 'Addr',
        shipmentNos: Array.from({ length: 201 }, (_, i) => `T${i}`)
      });
    expect(createTooManyNos.status).toBe(400);
    assertNoStoreHeaders(createTooManyNos as unknown as { headers: Record<string, string> });

    const deleteTooLongId = await request(app.getHttpServer())
      .delete(`/v1/reservations/R${'1'.repeat(64)}?mode=standard&address=Addr`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(deleteTooLongId.status).toBe(400);
    assertNoStoreHeaders(deleteTooLongId as unknown as { headers: Record<string, string> });

    const deleteTooLongAddress = await request(app.getHttpServer())
      .delete(`/v1/reservations/R001?mode=standard&address=${'A'.repeat(513)}`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(deleteTooLongAddress.status).toBe(400);
    assertNoStoreHeaders(deleteTooLongAddress as unknown as { headers: Record<string, string> });
  });

  it('P3_CREATE_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized reservation create response', async () => {
    (mockLegacySoapClient.createReservation as jest.Mock).mockResolvedValueOnce({
      reservationNo: `R${'1'.repeat(64)}`,
      mode: 'standard'
    });

    const response = await request(app.getHttpServer())
      .post('/v1/reservations?mode=standard')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        address: 'Addr',
        shipmentNos: ['T001']
      });

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P4_ERROR_RESPONSE_MAXLEN_ENFORCEMENT truncates oversized error message', async () => {
    (mockLegacySoapClient.getShipment as jest.Mock).mockRejectedValueOnce(
      new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'e'.repeat(1400))
    );

    const response = await request(app.getHttpServer())
      .get('/v1/shipments/T001')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    expect(typeof response.body.message).toBe('string');
    expect(response.body.message.length).toBeLessThanOrEqual(1024);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P4_HEALTH_RESPONSE_CONTRACT returns valid length and datetime format', async () => {
    const response = await request(app.getHttpServer()).get('/v1/health');

    expect(response.status).toBe(200);
    expect(typeof response.body.status).toBe('string');
    expect(typeof response.body.service).toBe('string');
    expect(typeof response.body.timestamp).toBe('string');
    expect(response.body.status.length).toBeLessThanOrEqual(32);
    expect(response.body.service.length).toBeLessThanOrEqual(64);
    expect(response.body.timestamp.length).toBeLessThanOrEqual(40);
    expect(Number.isNaN(Date.parse(response.body.timestamp))).toBe(false);
  });

  it('POST /push/register returns no-store headers', async () => {
    const response = await request(app.getHttpServer())
      .post('/v1/push/register')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        deviceId: 'device-1',
        platform: 'android',
        fcmToken: 'fcm-token-1',
        appVersion: 1
      });

    expect(response.status).toBe(200);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });
});
