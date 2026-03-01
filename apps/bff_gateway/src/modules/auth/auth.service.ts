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
import { readPositiveInt } from '../../core/config/number-env';
import { AuthClaims } from '../../security/auth-claims';
import { RedisTokenStoreService } from '../../security/redis-token-store.service';
import { LoginRequestDto } from './dto/login-request.dto';

export interface WebviewBootstrapDto {
  baseUrl: string;
  registerUrl: string;
  resetPasswordUrl: string;
  cookies: WebCookieModel[];
}

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly legacySoapClient: LegacySoapClient,
    private readonly tokenStore: RedisTokenStoreService
  ) {}

  async login(dto: LoginRequestDto): Promise<Record<string, unknown>> {
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

    return {
      accessToken,
      refreshToken,
      user: {
        id: legacyUser.id,
        contractNo: legacyUser.contractNo,
        name: legacyUser.displayName,
        role: legacyUser.role
      },
      webviewBootstrap
    };
  }

  async refresh(refreshToken: string): Promise<Record<string, unknown>> {
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
      accessToken,
      refreshToken: rotatedRefreshToken
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
      'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1'
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
    return { baseUrl, registerUrl, resetPasswordUrl, cookies };
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
}
