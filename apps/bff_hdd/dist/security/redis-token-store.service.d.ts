import { OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
export interface RefreshTokenState {
    userId: string;
    account: string;
    role: string;
    contractNo: string;
    identify: string;
    platform: 'android' | 'ios';
    deviceId: string;
}
export declare class RedisTokenStoreService implements OnModuleInit, OnModuleDestroy {
    private readonly configService;
    private readonly logger;
    private readonly redis;
    private ready;
    constructor(configService: ConfigService);
    onModuleInit(): Promise<void>;
    onModuleDestroy(): Promise<void>;
    ensureReady(): Promise<void>;
    issueToken(state: RefreshTokenState, ttlSeconds: number): Promise<string>;
    consumeToken(token: string): Promise<RefreshTokenState | null>;
    revokeToken(token: string): Promise<boolean>;
    private getKey;
}
