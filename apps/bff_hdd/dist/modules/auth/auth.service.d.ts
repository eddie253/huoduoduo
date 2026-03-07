import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { RedisTokenStoreService } from '../../security/redis-token-store.service';
import { LoginResponseDto, RefreshResponseDto, WebviewBootstrapDto } from './dto/auth-response.dto';
import { LoginRequestDto } from './dto/login-request.dto';
export declare class AuthService {
    private readonly jwtService;
    private readonly configService;
    private readonly legacySoapClient;
    private readonly tokenStore;
    constructor(jwtService: JwtService, configService: ConfigService, legacySoapClient: LegacySoapClient, tokenStore: RedisTokenStoreService);
    login(dto: LoginRequestDto): Promise<LoginResponseDto>;
    refresh(refreshToken: string): Promise<RefreshResponseDto>;
    logout(refreshToken?: string): Promise<{
        revoked: boolean;
    }>;
    getWebviewBootstrap(account: string, identify: string): Promise<WebviewBootstrapDto>;
    private computeIdentify;
    private buildClaims;
    private getRefreshTtlSeconds;
    private ensureTokenStoreReady;
    private enforceCookieContract;
    private requireString;
}
