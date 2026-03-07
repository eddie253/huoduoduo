import { ConfigService } from '@nestjs/config';
import { OnModuleDestroy, OnModuleInit } from '@nestjs/common/interfaces';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { DriverLocationDto } from './dto/driver-location.dto';
export declare class DriverLocationService implements OnModuleInit, OnModuleDestroy {
    private readonly configService;
    private readonly legacySoapClient;
    private readonly logger;
    private readonly redis;
    private flushTimer?;
    constructor(configService: ConfigService, legacySoapClient: LegacySoapClient);
    onModuleInit(): Promise<void>;
    onModuleDestroy(): Promise<void>;
    submitLocation(dto: DriverLocationDto): Promise<{
        ok: boolean;
    }>;
    submitLocationsBatch(dtos: DriverLocationDto[]): Promise<{
        ok: boolean;
    }>;
    flushPendingLocations(): Promise<void>;
    private toPayload;
    private saveSingleToRedis;
    private saveBatchToRedis;
    private flushTrackingNo;
    private listKey;
}
