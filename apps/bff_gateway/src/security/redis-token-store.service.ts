import { Injectable, Logger, OnModuleDestroy, OnModuleInit, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'crypto';
import { createClient, RedisClientType } from 'redis';

export interface RefreshTokenState {
  userId: string;
  account: string;
  role: string;
  contractNo: string;
  identify: string;
  platform: 'android' | 'ios';
  deviceId: string;
}

@Injectable()
export class RedisTokenStoreService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisTokenStoreService.name);
  private readonly redis: RedisClientType;
  private ready = false;

  constructor(private readonly configService: ConfigService) {
    const redisUrl = this.configService.get<string>('REDIS_URL', 'redis://localhost:6379');
    this.redis = createClient({ url: redisUrl });
    this.redis.on('error', (error) => {
      this.ready = false;
      this.logger.error(`Redis error: ${error.message}`);
    });
  }

  async onModuleInit(): Promise<void> {
    await this.redis.connect();
    await this.redis.ping();
    this.ready = true;
    this.logger.log('Redis token store connected.');
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis.isOpen) {
      await this.redis.quit();
    }
  }

  async ensureReady(): Promise<void> {
    if (!this.ready || !this.redis.isReady) {
      throw new ServiceUnavailableException('Token store unavailable.');
    }
    try {
      await this.redis.ping();
    } catch {
      this.ready = false;
      throw new ServiceUnavailableException('Token store unavailable.');
    }
  }

  async issueToken(state: RefreshTokenState, ttlSeconds: number): Promise<string> {
    await this.ensureReady();
    const token = randomUUID();
    const key = this.getKey(token);
    await this.redis.set(key, JSON.stringify(state), { EX: ttlSeconds });
    return token;
  }

  async consumeToken(token: string): Promise<RefreshTokenState | null> {
    await this.ensureReady();
    const key = this.getKey(token);
    const value = await this.redis.get(key);
    if (!value) {
      return null;
    }
    await this.redis.del(key);
    return JSON.parse(value) as RefreshTokenState;
  }

  async revokeToken(token: string): Promise<boolean> {
    await this.ensureReady();
    const key = this.getKey(token);
    const deleted = await this.redis.del(key);
    return deleted > 0;
  }

  private getKey(token: string): string {
    const hash = createHash('sha256').update(token).digest('hex');
    return `rt:{${hash}}`;
  }
}
