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
var IdempotencyGuardService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.IdempotencyGuardService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const redis_1 = require("redis");
let IdempotencyGuardService = IdempotencyGuardService_1 = class IdempotencyGuardService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(IdempotencyGuardService_1.name);
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
            this.logger.log('Idempotency guard connected to Redis');
        }
    }
    async onModuleDestroy() {
        if (this.redis.isOpen) {
            await this.redis.quit();
        }
    }
    async ensureUnique(scope, key, ttlSeconds) {
        if (!key) {
            throw new common_1.ServiceUnavailableException('Missing idempotency key');
        }
        try {
            const namespacedKey = this.buildKey(scope, key);
            const result = await this.redis.set(namespacedKey, '1', { NX: true, EX: ttlSeconds });
            return result === 'OK';
        }
        catch (error) {
            this.logger.error(`Idempotency guard redis failure: ${error.message}`);
            throw new common_1.ServiceUnavailableException('Idempotency guard unavailable.');
        }
    }
    buildKey(scope, key) {
        return `idem:{${scope}}:{${key}}`;
    }
};
exports.IdempotencyGuardService = IdempotencyGuardService;
exports.IdempotencyGuardService = IdempotencyGuardService = IdempotencyGuardService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], IdempotencyGuardService);
//# sourceMappingURL=idempotency-guard.service.js.map