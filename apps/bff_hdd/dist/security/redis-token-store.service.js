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
var RedisTokenStoreService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisTokenStoreService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const crypto_1 = require("crypto");
const redis_1 = require("redis");
let RedisTokenStoreService = RedisTokenStoreService_1 = class RedisTokenStoreService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(RedisTokenStoreService_1.name);
        this.ready = false;
        const redisUrl = this.configService.get('REDIS_URL', 'redis://localhost:6379');
        this.redis = (0, redis_1.createClient)({ url: redisUrl });
        this.redis.on('error', (error) => {
            this.ready = false;
            this.logger.error(`Redis error: ${error.message}`);
        });
    }
    async onModuleInit() {
        await this.redis.connect();
        await this.redis.ping();
        this.ready = true;
        this.logger.log('Redis token store connected.');
    }
    async onModuleDestroy() {
        if (this.redis.isOpen) {
            await this.redis.quit();
        }
    }
    async ensureReady() {
        if (!this.redis.isReady) {
            this.ready = false;
            throw new common_1.ServiceUnavailableException('Token store unavailable.');
        }
        try {
            await this.redis.ping();
            this.ready = true;
        }
        catch {
            this.ready = false;
            throw new common_1.ServiceUnavailableException('Token store unavailable.');
        }
    }
    async issueToken(state, ttlSeconds) {
        await this.ensureReady();
        const token = (0, crypto_1.randomUUID)();
        const key = this.getKey(token);
        await this.redis.set(key, JSON.stringify(state), { EX: ttlSeconds });
        return token;
    }
    async consumeToken(token) {
        await this.ensureReady();
        const key = this.getKey(token);
        const value = await this.redis.get(key);
        if (!value) {
            return null;
        }
        await this.redis.del(key);
        return JSON.parse(value);
    }
    async revokeToken(token) {
        await this.ensureReady();
        const key = this.getKey(token);
        const deleted = await this.redis.del(key);
        return deleted > 0;
    }
    getKey(token) {
        const hash = (0, crypto_1.createHash)('sha256').update(token).digest('hex');
        return `rt:{${hash}}`;
    }
};
exports.RedisTokenStoreService = RedisTokenStoreService;
exports.RedisTokenStoreService = RedisTokenStoreService = RedisTokenStoreService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], RedisTokenStoreService);
//# sourceMappingURL=redis-token-store.service.js.map