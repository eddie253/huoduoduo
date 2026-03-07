import { HttpException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { DriverLocationService } from './driver-location.service';

const mockRedis = {
  isOpen: false,
  on: jest.fn(),
  connect: jest.fn(async () => undefined),
  ping: jest.fn(async () => 'PONG'),
  quit: jest.fn(async () => undefined),
  rPush: jest.fn(async () => 1),
  expire: jest.fn(async () => 1),
  sAdd: jest.fn(async () => 1),
  sMembers: jest.fn(async () => []),
  sRem: jest.fn(async () => 1),
  lPop: jest.fn(async () => null),
  lPush: jest.fn(async () => 1),
  multi: jest.fn(() => ({
    rPush: jest.fn().mockReturnThis(),
    expire: jest.fn().mockReturnThis(),
    sAdd: jest.fn().mockReturnThis(),
    exec: jest.fn(async () => undefined)
  }))
};

jest.mock('redis', () => ({
  createClient: jest.fn(() => mockRedis)
}));

describe('DriverLocationService', () => {
  const config = {
    get: jest.fn(() => 'redis://localhost:6379')
  } as unknown as ConfigService;

  const legacySoapClient = {
    reportDriverLocation: jest.fn(async () => undefined)
  } as unknown as LegacySoapClient;

  beforeEach(() => {
    jest.clearAllMocks();
    mockRedis.isOpen = false;
  });

  it('rejects batch larger than 20', async () => {
    const service = new DriverLocationService(config, legacySoapClient);
    const payload = new Array(21).fill(0).map((_, index) => ({
      trackingNo: `T${index}`,
      lat: '25.0',
      lng: '121.0'
    }));

    await expect(service.submitLocationsBatch(payload)).rejects.toBeInstanceOf(HttpException);
  });

  it('stores single location into redis', async () => {
    const service = new DriverLocationService(config, legacySoapClient);

    await expect(
      service.submitLocation({
        trackingNo: 'T001',
        lat: '25.0',
        lng: '121.0'
      })
    ).resolves.toEqual({ ok: true });

    expect(mockRedis.rPush).toHaveBeenCalledTimes(1);
    expect(mockRedis.sAdd).toHaveBeenCalledWith('driver-location:pending-keys', 'T001');
  });
});
