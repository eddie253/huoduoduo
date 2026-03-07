import { ConfigService } from '@nestjs/config';
import { OnModuleDestroy, OnModuleInit } from '@nestjs/common/interfaces';
export declare class IdempotencyGuardService implements OnModuleInit, OnModuleDestroy {
    private readonly configService;
    private readonly logger;
    private readonly redis;
    constructor(configService: ConfigService);
    onModuleInit(): Promise<void>;
    onModuleDestroy(): Promise<void>;
    ensureUnique(scope: string, key: string, ttlSeconds: number): Promise<boolean>;
    private buildKey;
}
