"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const jwt_1 = require("@nestjs/jwt");
const crypto_1 = require("crypto");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const legacy_soap_error_1 = require("../../adapters/soap/legacy-soap.error");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const number_env_1 = require("../../core/config/number-env");
const redis_token_store_service_1 = require("../../security/redis-token-store.service");
let AuthService = class AuthService {
    constructor(jwtService, configService, legacySoapClient, tokenStore) {
        this.jwtService = jwtService;
        this.configService = configService;
        this.legacySoapClient = legacySoapClient;
        this.tokenStore = tokenStore;
    }
    async login(dto) {
        await this.ensureTokenStoreReady();
        const legacyUser = await this.legacySoapClient.validateLogin(dto.account, dto.password);
        if (!legacyUser) {
            throw new common_1.UnauthorizedException('Invalid credentials.');
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
        const refreshToken = await this.tokenStore.issueToken({
            userId: legacyUser.id,
            account: legacyUser.account,
            role: legacyUser.role,
            contractNo: legacyUser.contractNo,
            identify,
            platform: dto.platform,
            deviceId: dto.deviceId
        }, refreshTtlSec);
        const webviewBootstrap = await this.getWebviewBootstrap(legacyUser.account, identify);
        const user = {
            id: (0, p1_contract_policy_1.ensureMax)('auth.login.user.id', legacyUser.id, p1_contract_policy_1.P1_CONTRACT_LIMITS.userId),
            contractNo: (0, p1_contract_policy_1.ensureMax)('auth.login.user.contractNo', legacyUser.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo),
            name: (0, p1_contract_policy_1.truncateMax)(legacyUser.displayName, p1_contract_policy_1.P1_CONTRACT_LIMITS.userName),
            role: (0, p1_contract_policy_1.ensureMax)('auth.login.user.role', legacyUser.role, p1_contract_policy_1.P1_CONTRACT_LIMITS.role)
        };
        return {
            accessToken: (0, p1_contract_policy_1.ensureMax)('auth.login.accessToken', accessToken, p1_contract_policy_1.P1_CONTRACT_LIMITS.token),
            refreshToken: (0, p1_contract_policy_1.ensureMax)('auth.login.refreshToken', refreshToken, p1_contract_policy_1.P1_CONTRACT_LIMITS.refreshToken),
            user,
            webviewBootstrap
        };
    }
    async refresh(refreshToken) {
        if (!refreshToken) {
            throw new common_1.ForbiddenException('Missing refresh token.');
        }
        await this.ensureTokenStoreReady();
        const state = await this.tokenStore.consumeToken(refreshToken);
        if (!state) {
            throw new common_1.ForbiddenException('Refresh token revoked or expired.');
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
            accessToken: (0, p1_contract_policy_1.ensureMax)('auth.refresh.accessToken', accessToken, p1_contract_policy_1.P1_CONTRACT_LIMITS.token),
            refreshToken: (0, p1_contract_policy_1.ensureMax)('auth.refresh.refreshToken', rotatedRefreshToken, p1_contract_policy_1.P1_CONTRACT_LIMITS.refreshToken)
        };
    }
    async logout(refreshToken) {
        if (!refreshToken) {
            return { revoked: false };
        }
        await this.ensureTokenStoreReady();
        return { revoked: await this.tokenStore.revokeToken(refreshToken) };
    }
    async getWebviewBootstrap(account, identify) {
        const baseUrl = this.configService.get('WEBVIEW_BASE_URL', 'https://old.huoduoduo.com.tw/app/rvt/ge.aspx');
        const registerUrl = this.configService.get('WEBVIEW_REGISTER_URL', 'https://old.huoduoduo.com.tw/register/register.aspx');
        const resetPasswordUrl = this.configService.get('WEBVIEW_RESET_URL', 'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx');
        const cookies = await this.legacySoapClient.buildWebviewCookies(account, identify);
        (0, p1_contract_policy_1.ensureMaxItems)('auth.webviewBootstrap.cookies', cookies.length, p1_contract_policy_1.P1_CONTRACT_LIMITS.cookieCount);
        return {
            baseUrl: (0, p1_contract_policy_1.ensureMax)('auth.webviewBootstrap.baseUrl', baseUrl, p1_contract_policy_1.P1_CONTRACT_LIMITS.url),
            registerUrl: (0, p1_contract_policy_1.ensureMax)('auth.webviewBootstrap.registerUrl', registerUrl, p1_contract_policy_1.P1_CONTRACT_LIMITS.url),
            resetPasswordUrl: (0, p1_contract_policy_1.ensureMax)('auth.webviewBootstrap.resetPasswordUrl', resetPasswordUrl, p1_contract_policy_1.P1_CONTRACT_LIMITS.url),
            cookies: cookies.map((cookie, index) => this.enforceCookieContract(cookie, index))
        };
    }
    computeIdentify(password) {
        return (0, crypto_1.createHash)('sha512').update(Buffer.from(password)).digest('base64');
    }
    buildClaims(payload) {
        return {
            sub: payload.userId,
            account: payload.account,
            role: payload.role,
            contractNo: payload.contractNo,
            identify: payload.identify,
            platform: payload.platform,
            deviceId: payload.deviceId,
            jti: (0, crypto_1.randomUUID)()
        };
    }
    getRefreshTtlSeconds() {
        return (0, number_env_1.readPositiveInt)(this.configService.get('REFRESH_TOKEN_TTL_SECONDS'), 604800, 'REFRESH_TOKEN_TTL_SECONDS');
    }
    async ensureTokenStoreReady() {
        try {
            await this.tokenStore.ensureReady();
        }
        catch {
            throw new common_1.ServiceUnavailableException('Token store unavailable.');
        }
    }
    enforceCookieContract(cookie, index) {
        if (typeof cookie.secure !== 'boolean' || typeof cookie.httpOnly !== 'boolean') {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `auth.webviewBootstrap.cookies[${index}] boolean fields invalid.`);
        }
        return {
            name: (0, p1_contract_policy_1.ensureMax)(`auth.webviewBootstrap.cookies[${index}].name`, this.requireString(cookie.name, `auth.webviewBootstrap.cookies[${index}].name`), p1_contract_policy_1.P1_CONTRACT_LIMITS.cookieName),
            value: (0, p1_contract_policy_1.ensureMax)(`auth.webviewBootstrap.cookies[${index}].value`, this.requireString(cookie.value, `auth.webviewBootstrap.cookies[${index}].value`), p1_contract_policy_1.P1_CONTRACT_LIMITS.cookieValue),
            domain: (0, p1_contract_policy_1.ensureMax)(`auth.webviewBootstrap.cookies[${index}].domain`, this.requireString(cookie.domain, `auth.webviewBootstrap.cookies[${index}].domain`), p1_contract_policy_1.P1_CONTRACT_LIMITS.cookieDomain),
            path: (0, p1_contract_policy_1.ensureMax)(`auth.webviewBootstrap.cookies[${index}].path`, this.requireString(cookie.path, `auth.webviewBootstrap.cookies[${index}].path`), p1_contract_policy_1.P1_CONTRACT_LIMITS.cookiePath),
            secure: cookie.secure,
            httpOnly: cookie.httpOnly
        };
    }
    requireString(value, field) {
        if (typeof value !== 'string') {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be string.`);
        }
        return value;
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [jwt_1.JwtService,
        config_1.ConfigService,
        legacy_soap_client_1.LegacySoapClient,
        redis_token_store_service_1.RedisTokenStoreService])
], AuthService);
//# sourceMappingURL=auth.service.js.map