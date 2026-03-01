import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
// eslint-disable-next-line @typescript-eslint/no-require-imports
import request = require('supertest');
import { AppModule } from './app.module';
import { LegacySoapClient, LegacyUser, WebCookieModel } from './adapters/soap/legacy-soap.client';
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
  const submitShipmentDelivery = jest.fn();
  const assertNoStoreHeaders = (result: { headers: Record<string, string> }): void => {
    expect(result.headers['cache-control']).toBe('no-store, no-cache, must-revalidate');
    expect(result.headers.pragma).toBe('no-cache');
    expect(result.headers.expires).toBe('0');
  };

  beforeAll(async () => {
    const mockLegacySoapClient: Partial<LegacySoapClient> = {
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

  it('GET /bootstrap/webview returns cookies payload', async () => {
    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'cookie_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const result = await request(app.getHttpServer())
      .get('/v1/bootstrap/webview')
      .set('Authorization', `Bearer ${login.body.accessToken}`);

    expect(result.status).toBe(200);
    expect(result.body.baseUrl).toBeDefined();
    expect(Array.isArray(result.body.cookies)).toBe(true);
    expect(result.body.cookies.length).toBeGreaterThanOrEqual(3);
    assertNoStoreHeaders(result as unknown as { headers: Record<string, string> });
  });

  it('GET /bootstrap/webview returns 401 when missing authorization', async () => {
    const result = await request(app.getHttpServer()).get('/v1/bootstrap/webview');
    expect(result.status).toBe(401);
    assertNoStoreHeaders(result as unknown as { headers: Record<string, string> });
  });

  it('POST /shipments/{id}/delivery forwards payload to legacy client', async () => {
    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'delivery_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const payload = {
      imageBase64: 'abc',
      imageFileName: 'proof.jpg',
      latitude: '25.03',
      longitude: '121.56'
    };

    const response = await request(app.getHttpServer())
      .post('/v1/shipments/T001/delivery')
      .set('Authorization', `Bearer ${login.body.accessToken}`)
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
    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'shipment_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const response = await request(app.getHttpServer())
      .get('/v1/shipments/T001')
      .set('Authorization', `Bearer ${login.body.accessToken}`);

    expect(response.status).toBe(200);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('GET /reservations returns no-store headers', async () => {
    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'reservation_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const response = await request(app.getHttpServer())
      .get('/v1/reservations?mode=standard')
      .set('Authorization', `Bearer ${login.body.accessToken}`);

    expect(response.status).toBe(200);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('POST /push/register returns no-store headers', async () => {
    const login = await request(app.getHttpServer()).post('/v1/auth/login').send({
      account: 'push_user',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const response = await request(app.getHttpServer())
      .post('/v1/push/register')
      .set('Authorization', `Bearer ${login.body.accessToken}`)
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
