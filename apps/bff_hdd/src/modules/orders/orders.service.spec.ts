import { BadRequestException, ConflictException } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { IdempotencyGuardService } from '../../shared/idempotency/idempotency-guard.service';
import { AuthClaims } from '../../security/auth-claims';
import { OrdersService } from './orders.service';

describe('OrdersService', () => {
  const claims: AuthClaims = {
    sub: 'D001',
    account: 'driver',
    role: 'driver',
    contractNo: 'D001',
    identify: 'identify',
    platform: 'android',
    deviceId: 'device-1',
    jti: 'jti-1'
  };

  it('requires X-Idempotency-Key', async () => {
    const legacySoapClient = {
      acceptOrder: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;
    const guard = {
      ensureUnique: jest.fn(async () => true)
    } as unknown as IdempotencyGuardService;
    const service = new OrdersService(legacySoapClient, guard);

    await expect(service.acceptOrder('T001', claims, '')).rejects.toBeInstanceOf(BadRequestException);
  });

  it('maps duplicate idempotency to 409', async () => {
    const legacySoapClient = {
      acceptOrder: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;
    const guard = {
      ensureUnique: jest.fn(async () => false)
    } as unknown as IdempotencyGuardService;
    const service = new OrdersService(legacySoapClient, guard);

    await expect(service.acceptOrder('T001', claims, 'k1')).rejects.toBeInstanceOf(ConflictException);
  });

  it('maps legacy already-taken error to 409', async () => {
    const legacySoapClient = {
      acceptOrder: jest.fn(async () => {
        throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, '此貨件已被接單');
      })
    } as unknown as LegacySoapClient;
    const guard = {
      ensureUnique: jest.fn(async () => true)
    } as unknown as IdempotencyGuardService;
    const service = new OrdersService(legacySoapClient, guard);

    await expect(service.acceptOrder('T001', claims, 'k2')).rejects.toBeInstanceOf(ConflictException);
  });

  it('accepts order successfully', async () => {
    const legacySoapClient = {
      acceptOrder: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;
    const guard = {
      ensureUnique: jest.fn(async () => true)
    } as unknown as IdempotencyGuardService;
    const service = new OrdersService(legacySoapClient, guard);

    await expect(service.acceptOrder('T001', claims, 'k3')).resolves.toEqual({ ok: true });
  });
});
