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
      getReservationZipAreas: jest.fn(async () => [
        {
          code: 'ARVZIP001',
          name: 'Taipei Area',
          status: 'open',
          service: 'reservation',
          role: null,
          message: null,
          reservationNo: null,
          trackingNo: null,
          zip: '100',
          areaCode: 'A1',
          address: null,
          date: '2026-03-04'
        }
      ]),
      getReservationAvailable: jest.fn(async () => [
        {
          code: 'ARV001',
          name: 'Reservable Standard',
          status: 'open',
          service: 'reservation',
          role: null,
          message: null,
          reservationNo: null,
          trackingNo: 'T001',
          zip: '100',
          areaCode: null,
          address: 'Addr',
          date: '2026-03-04'
        }
      ]),
      getReservationAvailableBulk: jest.fn(async () => [
        {
          code: 'BARV001',
          name: 'Reservable Bulk',
          status: 'open',
          service: 'reservation',
          role: null,
          message: null,
          reservationNo: null,
          trackingNo: 'B001',
          zip: '100',
          areaCode: null,
          address: 'Addr',
          date: '2026-03-04'
        }
      ]),
      getReservationAreaCodes: jest.fn(async () => [
        {
          code: 'AREA001',
          name: 'Area Code',
          status: 'active',
          service: 'reservation',
          role: null,
          message: null,
          reservationNo: null,
          trackingNo: null,
          zip: '100',
          areaCode: 'A1',
          address: null,
          date: '2026-03-04'
        }
      ]),
      getReservationArrived: jest.fn(async () => [
        {
          code: 'ARR001',
          name: 'Arrived Shipment',
          status: 'arrived',
          service: 'reservation',
          role: null,
          message: null,
          reservationNo: null,
          trackingNo: 'T009',
          zip: '100',
          areaCode: null,
          address: 'Warehouse',
          date: '2026-03-04'
        }
      ]),
      getProxyMates: jest.fn(async () => [
        {
          code: 'P001',
          name: 'Proxy Mate',
          area: 'A1',
          status: 'active',
          service: 'proxy',
          role: null,
          message: null,
          updatedAt: '2026-03-04T00:00:00Z'
        }
      ]),
      searchProxyKpi: jest.fn(async () => [
        {
          code: 'K001',
          name: 'KPI Search',
          status: 'ok',
          service: 'proxy-kpi',
          role: null,
          message: null,
          updatedAt: '2026-03-04T00:00:00Z'
        }
      ]),
      getProxyKpi: jest.fn(async () => [
        {
          code: 'K002',
          name: 'KPI Monthly',
          status: 'ok',
          service: 'proxy-kpi',
          role: null,
          message: null,
          updatedAt: '2026-03-04T00:00:00Z'
        }
      ]),
      getProxyKpiDaily: jest.fn(async () => [
        {
          code: 'K003',
          name: 'KPI Daily',
          status: 'ok',
          service: 'proxy-kpi',
          role: null,
          message: null,
          updatedAt: '2026-03-04T00:00:00Z'
        }
      ]),
      getDriverCurrency: jest.fn(async () => [
        {
          code: 'CY001',
          name: 'Daily Currency',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: null,
          address: null,
          date: '2026-03-04',
          amount: 100,
          balance: 1000
        }
      ]),
      getDriverCurrencyMonth: jest.fn(async () => [
        {
          code: 'CY002',
          name: 'Monthly Currency',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: null,
          address: null,
          date: '2026-03',
          amount: 200,
          balance: 1200
        }
      ]),
      getDriverBalance: jest.fn(async () => [
        {
          code: 'CY003',
          name: 'Balance',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: null,
          address: null,
          date: '2026-03-04',
          amount: null,
          balance: 1300
        }
      ]),
      getDepositHead: jest.fn(async () => [
        {
          code: 'CY004',
          name: 'Deposit Head',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: null,
          address: null,
          date: '2026-03-04',
          amount: 300,
          balance: null
        }
      ]),
      getDepositBody: jest.fn(async () => [
        {
          code: 'CY005',
          name: 'Deposit Body',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: 'T001',
          address: 'Addr',
          date: '2026-03-04',
          amount: 50,
          balance: null
        }
      ]),
      getShipmentCurrency: jest.fn(async () => [
        {
          code: 'CY006',
          name: 'Shipment Currency',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: 'T001',
          address: null,
          date: '2026-03-04',
          amount: 80,
          balance: null
        }
      ]),
      updateRegId: jest.fn(async () => undefined),
      deleteRegId: jest.fn(async () => undefined),
      getVersion: jest.fn(async () => '123')
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

  it('GET /reservations/zip-areas returns no-store headers and response payload', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/reservations/zip-areas')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body.items)).toBe(true);
    expect(response.body.items[0].code).toBe('ARVZIP001');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P7_RESERVATION_WEB_SUPPORT_REQUEST_MAXLEN_VALIDATION returns 400 on over-length zip', async () => {
    const response = await request(app.getHttpServer())
      .get(`/v1/reservations/available?zip=Z${'1'.repeat(64)}`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(400);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P7_RESERVATION_WEB_SUPPORT_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized structural fields', async () => {
    (mockLegacySoapClient.getReservationAvailable as jest.Mock).mockResolvedValueOnce([
      {
        code: `C${'1'.repeat(64)}`,
        name: 'Reservable Standard',
        status: 'open',
        service: 'reservation',
        role: null,
        message: null,
        reservationNo: null,
        trackingNo: null,
        zip: '100',
        areaCode: null,
        address: null,
        date: '2026-03-04'
      }
    ]);

    const response = await request(app.getHttpServer())
      .get('/v1/reservations/available?zip=100')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

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

  it('GET /proxy/mates returns no-store headers and response payload', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/proxy/mates?area=A1')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body.items)).toBe(true);
    expect(response.body.items[0].code).toBe('P001');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P5_PROXY_KPI_REQUEST_MAXLEN_VALIDATION returns 400 on over-length query fields', async () => {
    const mates = await request(app.getHttpServer())
      .get(`/v1/proxy/mates?area=A${'1'.repeat(64)}`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(mates.status).toBe(400);
    assertNoStoreHeaders(mates as unknown as { headers: Record<string, string> });

    const kpi = await request(app.getHttpServer())
      .get('/v1/proxy/kpi?year=20266&month=03&area=A1')
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(kpi.status).toBe(400);
    assertNoStoreHeaders(kpi as unknown as { headers: Record<string, string> });

    const daily = await request(app.getHttpServer())
      .get('/v1/proxy/kpi/daily?date=20260304&area=A1')
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(daily.status).toBe(400);
    assertNoStoreHeaders(daily as unknown as { headers: Record<string, string> });
  });

  it('P5_PROXY_KPI_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized response fields', async () => {
    (mockLegacySoapClient.getProxyKpi as jest.Mock).mockResolvedValueOnce([
      {
        code: `C${'1'.repeat(64)}`,
        name: 'KPI',
        status: 'ok',
        service: 'proxy-kpi',
        role: null,
        message: null,
        updatedAt: null
      }
    ]);

    const response = await request(app.getHttpServer())
      .get('/v1/proxy/kpi?year=2026&month=03&area=A1')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('GET /currency/daily returns no-store headers and response payload', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/currency/daily?date=2026-03-04')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body.items)).toBe(true);
    expect(response.body.items[0].code).toBe('CY001');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P6_CURRENCY_QUERY_REQUEST_MAXLEN_VALIDATION returns 400 on over-length query fields', async () => {
    const daily = await request(app.getHttpServer())
      .get(`/v1/currency/daily?date=2${'0'.repeat(40)}`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(daily.status).toBe(400);
    assertNoStoreHeaders(daily as unknown as { headers: Record<string, string> });

    const depositBody = await request(app.getHttpServer())
      .get(`/v1/currency/deposit/body?tnum=T001&address=${'A'.repeat(513)}`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(depositBody.status).toBe(400);
    assertNoStoreHeaders(depositBody as unknown as { headers: Record<string, string> });

    const shipment = await request(app.getHttpServer())
      .get(`/v1/currency/shipment?orderNum=O${'1'.repeat(64)}`)
      .set('Authorization', `Bearer ${sharedAccessToken}`);
    expect(shipment.status).toBe(400);
    assertNoStoreHeaders(shipment as unknown as { headers: Record<string, string> });
  });

  it('P6_CURRENCY_RESPONSE_CONTRACT_ENFORCEMENT rejects oversized structural fields', async () => {
    (mockLegacySoapClient.getDriverCurrency as jest.Mock).mockResolvedValueOnce([
      {
        code: `C${'1'.repeat(64)}`,
        name: 'Daily Currency',
        status: 'ok',
        service: 'currency',
        role: null,
        message: null,
        currency: 'TWD',
        orderNo: null,
        address: null,
        date: '2026-03-04',
        amount: 100,
        balance: 1000
      }
    ]);

    const response = await request(app.getHttpServer())
      .get('/v1/currency/daily?date=2026-03-04')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
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

  it('POST /push/unregister returns no-store headers', async () => {
    const response = await request(app.getHttpServer())
      .post('/v1/push/unregister')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        fcmToken: 'fcm-token-1'
      });

    expect(response.status).toBe(200);
    expect(response.body.ok).toBe(true);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P9_PUSH_UNREGISTER_REQUEST_MAXLEN_VALIDATION returns 400 on over-length fcmToken', async () => {
    const response = await request(app.getHttpServer())
      .post('/v1/push/unregister')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        fcmToken: `f${'1'.repeat(4096)}`
      });

    expect(response.status).toBe(400);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('GET /system/version returns no-store headers and payload', async () => {
    const response = await request(app.getHttpServer()).get('/v1/system/version?name=DirverAPP');

    expect(response.status).toBe(200);
    expect(response.body.name).toBe('DirverAPP');
    expect(response.body.versionCode).toBe(123);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P9_SYSTEM_VERSION_QUERY_MAXLEN_VALIDATION returns 400 on over-length name', async () => {
    const response = await request(app.getHttpServer()).get(
      `/v1/system/version?name=D${'1'.repeat(64)}`
    );

    expect(response.status).toBe(400);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('P9_SYSTEM_VERSION_RESPONSE_CONTRACT_ENFORCEMENT rejects invalid legacy payload', async () => {
    (mockLegacySoapClient.getVersion as jest.Mock).mockResolvedValueOnce('invalid-version');

    const response = await request(app.getHttpServer()).get('/v1/system/version?name=DirverAPP');

    expect(response.status).toBe(502);
    expect(response.body.code).toBe('LEGACY_BAD_RESPONSE');
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('POST /orders/:trackingNo/accept returns 400 when missing idempotency key', async () => {
    const response = await request(app.getHttpServer())
      .post('/v1/orders/T001/accept')
      .set('Authorization', `Bearer ${sharedAccessToken}`);

    expect(response.status).toBe(400);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('POST /drivers/location accepts payload with auth', async () => {
    const response = await request(app.getHttpServer())
      .post('/v1/drivers/location')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send({
        trackingNo: 'T001',
        lat: '25.03',
        lng: '121.56',
        accuracyMeters: '12',
        recordedAt: '2026-03-07T04:40:00.000Z'
      });

    expect(response.status).toBe(201);
    expect(response.body.ok).toBe(true);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });

  it('POST /drivers/location/batch returns 413 when payload exceeds max batch size', async () => {
    const payload = new Array(21).fill(null).map((_, index) => ({
      trackingNo: `T${index}`,
      lat: '25.03',
      lng: '121.56'
    }));
    const response = await request(app.getHttpServer())
      .post('/v1/drivers/location/batch')
      .set('Authorization', `Bearer ${sharedAccessToken}`)
      .send(payload);

    expect(response.status).toBe(413);
    assertNoStoreHeaders(response as unknown as { headers: Record<string, string> });
  });
});
