import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OnModuleDestroy, OnModuleInit } from '@nestjs/common/interfaces';
import { createClient, RedisClientType } from 'redis';

@Injectable()
export class IdempotencyGuardService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(IdempotencyGuardService.name);
  private readonly redis: RedisClientType;

  constructor(private readonly configService: ConfigService) {
    const url = this.configService.get<string>('REDIS_URL', 'redis://localhost:6379');
    this.redis = createClient({ url });
    this.redis.on('error', (error) => {
      this.logger.error(`Redis error: ${error.message}`);
    });
  }

  async onModuleInit(): Promise<void> {
    if (!this.redis.isOpen) {
      await this.redis.connect();
      await this.redis.ping();
      this.logger.log('Idempotency guard connected to Redis');
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis.isOpen) {
      await this.redis.quit();
    }
  }

  async ensureUnique(scope: string, key: string, ttlSeconds: number): Promise<boolean> {
    if (!key) {
      throw new ServiceUnavailableException('Missing idempotency key');
    }
    try {
      const namespacedKey = this.buildKey(scope, key);
      const result = await this.redis.set(namespacedKey, '1', { NX: true, EX: ttlSeconds });
      return result === 'OK';
    } catch (error) {
      this.logger.error(`Idempotency guard redis failure: ${(error as Error).message}`);
      throw new ServiceUnavailableException('Idempotency guard unavailable.');
    }
  }

  private buildKey(scope: string, key: string): string {
    return `idem:{${scope}}:{${key}}`;
  }
}
