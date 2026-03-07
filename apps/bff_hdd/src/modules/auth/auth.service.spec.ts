import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { LegacySoapClient, LegacyUser, WebCookieModel } from '../../adapters/soap/legacy-soap.client';
import { RedisTokenStoreService, RefreshTokenState } from '../../security/redis-token-store.service';
import { AuthService } from './auth.service';

class InMemoryTokenStore {
  private readonly values = new Map<string, RefreshTokenState>();
  private counter = 0;

  async ensureReady(): Promise<void> {}

  async issueToken(state: RefreshTokenState, _ttlSeconds: number): Promise<string> {
    const token = `token-${++this.counter}`;
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

describe('AuthService token rotation', () => {
  it('invalidates old refresh token and rotates to a new one', async () => {
    const configService = {
      get: jest.fn((key: string, fallback: unknown) => {
        if (key === 'REFRESH_TOKEN_TTL_SECONDS') {
          return 604800;
        }
        if (key === 'WEBVIEW_BASE_URL') {
          return 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1';
        }
        if (key === 'WEBVIEW_REGISTER_URL') {
          return 'https://old.huoduoduo.com.tw/register/register.aspx';
        }
        if (key === 'WEBVIEW_RESET_URL') {
          return 'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx';
        }
        return fallback;
      })
    } as unknown as ConfigService;

    const jwtService = new JwtService({
      secret: 'test-secret',
      signOptions: { expiresIn: '900s' }
    });

    const legacySoapClient = {
      validateLogin: jest.fn(async () => {
        return {
          id: 'D001',
          account: 'tester',
          displayName: 'Tester',
          role: 'driver',
          contractNo: 'D001'
        } satisfies LegacyUser;
      }),
      buildWebviewCookies: jest.fn(async () => {
        return [] satisfies WebCookieModel[];
      })
    } as unknown as LegacySoapClient;

    const tokenStore = new InMemoryTokenStore() as unknown as RedisTokenStoreService;

    const service = new AuthService(jwtService, configService, legacySoapClient, tokenStore);
    const login = await service.login({
      account: 'tester',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    const oldRefresh = String(login.refreshToken);
    const rotated = await service.refresh(oldRefresh);
    expect(String(rotated.refreshToken)).not.toBe(oldRefresh);

    await expect(service.refresh(oldRefresh)).rejects.toThrow();
  });

  it('parses string refresh ttl config before issuing token', async () => {
    const configService = {
      get: jest.fn((key: string, fallback: unknown) => {
        if (key === 'REFRESH_TOKEN_TTL_SECONDS') {
          return '604800';
        }
        if (key === 'WEBVIEW_BASE_URL') {
          return 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1';
        }
        if (key === 'WEBVIEW_REGISTER_URL') {
          return 'https://old.huoduoduo.com.tw/register/register.aspx';
        }
        if (key === 'WEBVIEW_RESET_URL') {
          return 'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx';
        }
        return fallback;
      })
    } as unknown as ConfigService;

    const jwtService = new JwtService({
      secret: 'test-secret',
      signOptions: { expiresIn: '900s' }
    });

    const legacySoapClient = {
      validateLogin: jest.fn(async () => {
        return {
          id: 'D001',
          account: 'tester',
          displayName: 'Tester',
          role: 'driver',
          contractNo: 'D001'
        } satisfies LegacyUser;
      }),
      buildWebviewCookies: jest.fn(async () => {
        return [] satisfies WebCookieModel[];
      })
    } as unknown as LegacySoapClient;

    const tokenStore = {
      ensureReady: jest.fn(async () => undefined),
      issueToken: jest.fn(async () => 'token-1'),
      consumeToken: jest.fn(async () => null),
      revokeToken: jest.fn(async () => true)
    } as unknown as RedisTokenStoreService;

    const service = new AuthService(jwtService, configService, legacySoapClient, tokenStore);
    await service.login({
      account: 'tester',
      password: 'password123',
      deviceId: 'device-1',
      platform: 'android'
    });

    expect((tokenStore.issueToken as unknown as jest.Mock).mock.calls[0][1]).toBe(604800);
  });
});
