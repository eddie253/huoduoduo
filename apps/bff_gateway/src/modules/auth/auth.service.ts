import {
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomUUID } from 'crypto';
import { LegacySoapClient, WebCookieModel } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import {
  P1_CONTRACT_LIMITS,
  ensureMax,
  ensureMaxItems,
  truncateMax
} from '../../core/contracts/p1-contract-policy';
import { readPositiveInt } from '../../core/config/number-env';
import { AuthClaims } from '../../security/auth-claims';
import { RedisTokenStoreService } from '../../security/redis-token-store.service';
import {
  LoginResponseDto,
  RefreshResponseDto,
  UserProfileDto,
  WebviewBootstrapDto
} from './dto/auth-response.dto';
import { LoginRequestDto } from './dto/login-request.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly legacySoapClient: LegacySoapClient,
    private readonly tokenStore: RedisTokenStoreService
  ) {}

  async login(dto: LoginRequestDto): Promise<LoginResponseDto> {
    await this.ensureTokenStoreReady();

    const legacyUser = await this.legacySoapClient.validateLogin(dto.account, dto.password);
    if (!legacyUser) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const identify = this.computeIdentify(dto.password);
    const claims = this.buildClaims({
      userId: legacyUser.id,
      account: legacyUser.account,
      role: legacyUser.role,
      contractNo: legacyUser.contractNo,
      identify,
      platform: dto.platform,
      deviceId: dto.deviceId
    });
    const accessToken = await this.jwtService.signAsync(claims);

    const refreshTtlSec = this.getRefreshTtlSeconds();
    const refreshToken = await this.tokenStore.issueToken(
      {
        userId: legacyUser.id,
        account: legacyUser.account,
        role: legacyUser.role,
        contractNo: legacyUser.contractNo,
        identify,
        platform: dto.platform,
        deviceId: dto.deviceId
      },
      refreshTtlSec
    );

    const webviewBootstrap = await this.getWebviewBootstrap(legacyUser.account, identify);
    const user: UserProfileDto = {
      id: ensureMax('auth.login.user.id', legacyUser.id, P1_CONTRACT_LIMITS.userId),
      contractNo: ensureMax(
        'auth.login.user.contractNo',
        legacyUser.contractNo,
        P1_CONTRACT_LIMITS.contractNo
      ),
      name: truncateMax(legacyUser.displayName, P1_CONTRACT_LIMITS.userName),
      role: ensureMax('auth.login.user.role', legacyUser.role, P1_CONTRACT_LIMITS.role)
    };

    return {
      accessToken: ensureMax('auth.login.accessToken', accessToken, P1_CONTRACT_LIMITS.token),
      refreshToken: ensureMax(
        'auth.login.refreshToken',
        refreshToken,
        P1_CONTRACT_LIMITS.refreshToken
      ),
      user,
      webviewBootstrap
    };
  }

  async refresh(refreshToken: string): Promise<RefreshResponseDto> {
    if (!refreshToken) {
      throw new ForbiddenException('Missing refresh token.');
    }
    await this.ensureTokenStoreReady();
    const state = await this.tokenStore.consumeToken(refreshToken);
    if (!state) {
      throw new ForbiddenException('Refresh token revoked or expired.');
    }

    const claims = this.buildClaims({
      userId: state.userId,
      account: state.account,
      role: state.role,
      contractNo: state.contractNo,
      identify: state.identify,
      platform: state.platform,
      deviceId: state.deviceId
    });
    const accessToken = await this.jwtService.signAsync(claims);

    const refreshTtlSec = this.getRefreshTtlSeconds();
    const rotatedRefreshToken = await this.tokenStore.issueToken(state, refreshTtlSec);

    return {
      accessToken: ensureMax('auth.refresh.accessToken', accessToken, P1_CONTRACT_LIMITS.token),
      refreshToken: ensureMax(
        'auth.refresh.refreshToken',
        rotatedRefreshToken,
        P1_CONTRACT_LIMITS.refreshToken
      )
    };
  }

  async logout(refreshToken?: string): Promise<{ revoked: boolean }> {
    if (!refreshToken) {
      return { revoked: false };
    }
    await this.ensureTokenStoreReady();
    return { revoked: await this.tokenStore.revokeToken(refreshToken) };
  }

  async getWebviewBootstrap(account: string, identify: string): Promise<WebviewBootstrapDto> {
    const baseUrl = this.configService.get<string>(
      'WEBVIEW_BASE_URL',
      'https://old.huoduoduo.com.tw/app/rvt/ge.aspx'
    );
    const registerUrl = this.configService.get<string>(
      'WEBVIEW_REGISTER_URL',
      'https://old.huoduoduo.com.tw/register/register.aspx'
    );
    const resetPasswordUrl = this.configService.get<string>(
      'WEBVIEW_RESET_URL',
      'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx'
    );
    const cookies = await this.legacySoapClient.buildWebviewCookies(account, identify);
    ensureMaxItems('auth.webviewBootstrap.cookies', cookies.length, P1_CONTRACT_LIMITS.cookieCount);

    return {
      baseUrl: ensureMax('auth.webviewBootstrap.baseUrl', baseUrl, P1_CONTRACT_LIMITS.url),
      registerUrl: ensureMax('auth.webviewBootstrap.registerUrl', registerUrl, P1_CONTRACT_LIMITS.url),
      resetPasswordUrl: ensureMax(
        'auth.webviewBootstrap.resetPasswordUrl',
        resetPasswordUrl,
        P1_CONTRACT_LIMITS.url
      ),
      cookies: cookies.map((cookie, index) => this.enforceCookieContract(cookie, index))
    };
  }

  private computeIdentify(password: string): string {
    return createHash('sha512').update(Buffer.from(password)).digest('base64');
  }

  private buildClaims(payload: {
    userId: string;
    account: string;
    role: string;
    contractNo: string;
    identify: string;
    platform: 'android' | 'ios';
    deviceId: string;
  }): AuthClaims {
    return {
      sub: payload.userId,
      account: payload.account,
      role: payload.role,
      contractNo: payload.contractNo,
      identify: payload.identify,
      platform: payload.platform,
      deviceId: payload.deviceId,
      jti: randomUUID()
    };
  }

  private getRefreshTtlSeconds(): number {
    return readPositiveInt(
      this.configService.get('REFRESH_TOKEN_TTL_SECONDS'),
      604800,
      'REFRESH_TOKEN_TTL_SECONDS'
    );
  }

  private async ensureTokenStoreReady(): Promise<void> {
    try {
      await this.tokenStore.ensureReady();
    } catch {
      throw new ServiceUnavailableException('Token store unavailable.');
    }
  }

  private enforceCookieContract(cookie: WebCookieModel, index: number): WebCookieModel {
    if (typeof cookie.secure !== 'boolean' || typeof cookie.httpOnly !== 'boolean') {
      throw new LegacySoapError(
        'LEGACY_BAD_RESPONSE',
        502,
        `auth.webviewBootstrap.cookies[${index}] boolean fields invalid.`
      );
    }

    return {
      name: ensureMax(
        `auth.webviewBootstrap.cookies[${index}].name`,
        this.requireString(cookie.name, `auth.webviewBootstrap.cookies[${index}].name`),
        P1_CONTRACT_LIMITS.cookieName
      ),
      value: ensureMax(
        `auth.webviewBootstrap.cookies[${index}].value`,
        this.requireString(cookie.value, `auth.webviewBootstrap.cookies[${index}].value`),
        P1_CONTRACT_LIMITS.cookieValue
      ),
      domain: ensureMax(
        `auth.webviewBootstrap.cookies[${index}].domain`,
        this.requireString(cookie.domain, `auth.webviewBootstrap.cookies[${index}].domain`),
        P1_CONTRACT_LIMITS.cookieDomain
      ),
      path: ensureMax(
        `auth.webviewBootstrap.cookies[${index}].path`,
        this.requireString(cookie.path, `auth.webviewBootstrap.cookies[${index}].path`),
        P1_CONTRACT_LIMITS.cookiePath
      ),
      secure: cookie.secure,
      httpOnly: cookie.httpOnly
    };
  }

  private requireString(value: unknown, field: string): string {
    if (typeof value !== 'string') {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be string.`);
    }
    return value;
  }
}
