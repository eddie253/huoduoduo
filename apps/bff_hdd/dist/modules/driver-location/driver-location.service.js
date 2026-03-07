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
var DriverLocationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.DriverLocationService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const redis_1 = require("redis");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const MAX_BATCH_SIZE = 20;
const LOCATION_TTL_SECONDS = 3600;
const PENDING_KEYS_SET = 'driver-location:pending-keys';
const FLUSH_INTERVAL_MS = 5000;
let DriverLocationService = DriverLocationService_1 = class DriverLocationService {
    constructor(configService, legacySoapClient) {
        this.configService = configService;
        this.legacySoapClient = legacySoapClient;
        this.logger = new common_1.Logger(DriverLocationService_1.name);
        const url = this.configService.get('REDIS_URL', 'redis://localhost:6379');
        this.redis = (0, redis_1.createClient)({ url });
        this.redis.on('error', (error) => {
            this.logger.error(`Redis error: ${error.message}`);
        });
    }
    async onModuleInit() {
        if (!this.redis.isOpen) {
            await this.redis.connect();
            await this.redis.ping();
            this.logger.log('Driver location service connected to Redis');
        }
        this.flushTimer = setInterval(() => {
            void this.flushPendingLocations();
        }, FLUSH_INTERVAL_MS);
    }
    async onModuleDestroy() {
        if (this.flushTimer) {
            clearInterval(this.flushTimer);
            this.flushTimer = undefined;
        }
        if (this.redis.isOpen) {
            await this.redis.quit();
        }
    }
    async submitLocation(dto) {
        await this.saveSingleToRedis(dto.trackingNo, this.toPayload(dto));
        return { ok: true };
    }
    async submitLocationsBatch(dtos) {
        if (dtos.length > MAX_BATCH_SIZE) {
            throw new common_1.HttpException({ code: 'BATCH_TOO_LARGE', message: `Maximum batch size is ${MAX_BATCH_SIZE}` }, common_1.HttpStatus.PAYLOAD_TOO_LARGE);
        }
        await this.saveBatchToRedis(dtos.map((dto) => ({
            trackingNo: dto.trackingNo,
            payload: this.toPayload(dto)
        })));
        return { ok: true };
    }
    async flushPendingLocations() {
        try {
            const keys = await this.redis.sMembers(PENDING_KEYS_SET);
            for (const key of keys) {
                await this.flushTrackingNo(key);
            }
        }
        catch (error) {
            this.logger.error(`Driver location flush failed: ${error.message}`);
        }
    }
    toPayload(dto) {
        return {
            lat: dto.lat,
            lng: dto.lng,
            accuracyMeters: dto.accuracyMeters,
            recordedAt: dto.recordedAt ?? new Date().toISOString()
        };
    }
    async saveSingleToRedis(trackingNo, payload) {
        try {
            const key = this.listKey(trackingNo);
            await this.redis.rPush(key, JSON.stringify(payload));
            await this.redis.expire(key, LOCATION_TTL_SECONDS);
            await this.redis.sAdd(PENDING_KEYS_SET, trackingNo);
        }
        catch (error) {
            this.logger.error(`Failed to save driver location: ${error.message}`);
            throw new common_1.ServiceUnavailableException('Failed to save driver location');
        }
    }
    async saveBatchToRedis(items) {
        try {
            const tx = this.redis.multi();
            for (const item of items) {
                const key = this.listKey(item.trackingNo);
                tx.rPush(key, JSON.stringify(item.payload));
                tx.expire(key, LOCATION_TTL_SECONDS);
                tx.sAdd(PENDING_KEYS_SET, item.trackingNo);
            }
            await tx.exec();
        }
        catch (error) {
            this.logger.error(`Failed to save driver location batch: ${error.message}`);
            throw new common_1.ServiceUnavailableException('Failed to save driver location batch');
        }
    }
    async flushTrackingNo(trackingNo) {
        const key = this.listKey(trackingNo);
        while (true) {
            const raw = await this.redis.lPop(key);
            if (!raw) {
                await this.redis.sRem(PENDING_KEYS_SET, trackingNo);
                return;
            }
            try {
                const payload = JSON.parse(raw);
                await this.legacySoapClient.reportDriverLocation({
                    trackingNo,
                    lat: payload.lat,
                    lng: payload.lng,
                    accuracyMeters: payload.accuracyMeters,
                    recordedAt: payload.recordedAt
                });
            }
            catch (error) {
                await this.redis.lPush(key, raw);
                this.logger.warn(`Driver location flush retry queued for ${trackingNo}: ${error.message}`);
                return;
            }
        }
    }
    listKey(trackingNo) {
        return `driver-location:${trackingNo}`;
    }
};
exports.DriverLocationService = DriverLocationService;
exports.DriverLocationService = DriverLocationService = DriverLocationService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService,
        legacy_soap_client_1.LegacySoapClient])
], DriverLocationService);
//# sourceMappingURL=driver-location.service.js.map