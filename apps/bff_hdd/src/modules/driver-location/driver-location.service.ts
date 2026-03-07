import { HttpException, HttpStatus, Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OnModuleDestroy, OnModuleInit } from '@nestjs/common/interfaces';
import { createClient, RedisClientType } from 'redis';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { DriverLocationDto } from './dto/driver-location.dto';

const MAX_BATCH_SIZE = 20;
const LOCATION_TTL_SECONDS = 3600;
const PENDING_KEYS_SET = 'driver-location:pending-keys';
const FLUSH_INTERVAL_MS = 5000;

interface DriverLocationPayload {
  lat: string;
  lng: string;
  accuracyMeters?: string;
  recordedAt: string;
}

@Injectable()
export class DriverLocationService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DriverLocationService.name);
  private readonly redis: RedisClientType;
  private flushTimer?: NodeJS.Timeout;

  constructor(
    private readonly configService: ConfigService,
    private readonly legacySoapClient: LegacySoapClient
  ) {
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
      this.logger.log('Driver location service connected to Redis');
    }
    this.flushTimer = setInterval(() => {
      void this.flushPendingLocations();
    }, FLUSH_INTERVAL_MS);
  }

  async onModuleDestroy(): Promise<void> {
    if (this.flushTimer) {
      clearInterval(this.flushTimer);
      this.flushTimer = undefined;
    }
    if (this.redis.isOpen) {
      await this.redis.quit();
    }
  }

  async submitLocation(dto: DriverLocationDto): Promise<{ ok: boolean }> {
    await this.saveSingleToRedis(dto.trackingNo, this.toPayload(dto));
    return { ok: true };
  }

  async submitLocationsBatch(dtos: DriverLocationDto[]): Promise<{ ok: boolean }> {
    if (dtos.length > MAX_BATCH_SIZE) {
      throw new HttpException(
        { code: 'BATCH_TOO_LARGE', message: `Maximum batch size is ${MAX_BATCH_SIZE}` },
        HttpStatus.PAYLOAD_TOO_LARGE
      );
    }

    await this.saveBatchToRedis(
      dtos.map((dto) => ({
        trackingNo: dto.trackingNo,
        payload: this.toPayload(dto)
      }))
    );

    return { ok: true };
  }

  async flushPendingLocations(): Promise<void> {
    try {
      const keys = await this.redis.sMembers(PENDING_KEYS_SET);
      for (const key of keys) {
        await this.flushTrackingNo(key);
      }
    } catch (error) {
      this.logger.error(`Driver location flush failed: ${(error as Error).message}`);
    }
  }

  private toPayload(dto: DriverLocationDto): DriverLocationPayload {
    return {
      lat: dto.lat,
      lng: dto.lng,
      accuracyMeters: dto.accuracyMeters,
      recordedAt: dto.recordedAt ?? new Date().toISOString()
    };
  }

  private async saveSingleToRedis(trackingNo: string, payload: DriverLocationPayload): Promise<void> {
    try {
      const key = this.listKey(trackingNo);
      await this.redis.rPush(key, JSON.stringify(payload));
      await this.redis.expire(key, LOCATION_TTL_SECONDS);
      await this.redis.sAdd(PENDING_KEYS_SET, trackingNo);
    } catch (error) {
      this.logger.error(`Failed to save driver location: ${(error as Error).message}`);
      throw new ServiceUnavailableException('Failed to save driver location');
    }
  }

  private async saveBatchToRedis(
    items: Array<{
      trackingNo: string;
      payload: DriverLocationPayload;
    }>
  ): Promise<void> {
    try {
      const tx = this.redis.multi();
      for (const item of items) {
        const key = this.listKey(item.trackingNo);
        tx.rPush(key, JSON.stringify(item.payload));
        tx.expire(key, LOCATION_TTL_SECONDS);
        tx.sAdd(PENDING_KEYS_SET, item.trackingNo);
      }
      await tx.exec();
    } catch (error) {
      this.logger.error(`Failed to save driver location batch: ${(error as Error).message}`);
      throw new ServiceUnavailableException('Failed to save driver location batch');
    }
  }

  private async flushTrackingNo(trackingNo: string): Promise<void> {
    const key = this.listKey(trackingNo);
    while (true) {
      const raw = await this.redis.lPop(key);
      if (!raw) {
        await this.redis.sRem(PENDING_KEYS_SET, trackingNo);
        return;
      }

      try {
        const payload = JSON.parse(raw) as DriverLocationPayload;
        await this.legacySoapClient.reportDriverLocation({
          trackingNo,
          lat: payload.lat,
          lng: payload.lng,
          accuracyMeters: payload.accuracyMeters,
          recordedAt: payload.recordedAt
        });
      } catch (error) {
        await this.redis.lPush(key, raw);
        this.logger.warn(
          `Driver location flush retry queued for ${trackingNo}: ${(error as Error).message}`
        );
        return;
      }
    }
  }

  private listKey(trackingNo: string): string {
    return `driver-location:${trackingNo}`;
  }
}
