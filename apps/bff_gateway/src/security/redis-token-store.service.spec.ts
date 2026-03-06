import { ConfigService } from '@nestjs/config';
import { ServiceUnavailableException } from '@nestjs/common';
import { RedisTokenStoreService, RefreshTokenState } from './redis-token-store.service';

const mockConnect = jest.fn();
const mockPing = jest.fn();
const mockQuit = jest.fn();
const mockSet = jest.fn();
const mockGet = jest.fn();
const mockDel = jest.fn();
const mockOn = jest.fn();

let redisInstance: any;

jest.mock('redis', () => ({
  createClient: jest.fn(() => redisInstance)
}));

describe('RedisTokenStoreService', () => {
  const configService = {
    get: jest.fn((key: string, fallback?: string) => {
      if (key === 'REDIS_URL') {
        return 'redis://localhost:6379';
      }
      return fallback;
    })
  } as unknown as ConfigService;

  const buildService = () => new RedisTokenStoreService(configService);

  const sampleState: RefreshTokenState = {
    userId: 'U001',
    account: 'tester',
    role: 'driver',
    contractNo: 'C001',
    identify: 'ID001',
    platform: 'android',
    deviceId: 'device-1'
  };

  beforeEach(() => {
    jest.resetAllMocks();
    redisInstance = {
      on: mockOn.mockImplementation((event: string, handler: (...args: any[]) => void) => {
        if (event === 'error') {
          redisInstance.__errorHandler = handler;
        }
      }),
      connect: mockConnect.mockResolvedValue(undefined),
      ping: mockPing.mockResolvedValue('PONG'),
      quit: mockQuit.mockResolvedValue(undefined),
      set: mockSet.mockResolvedValue('OK'),
      get: mockGet.mockResolvedValue(null),
      del: mockDel.mockResolvedValue(0),
      isOpen: true,
      isReady: true
    };
  });

  it('connects on module init and marks ready', async () => {
    const service = buildService();
    await service.onModuleInit();

    expect(mockConnect).toHaveBeenCalledTimes(1);
    expect(mockPing).toHaveBeenCalledTimes(1);
    await expect(service.ensureReady()).resolves.toBeUndefined();
  });

  it('throws when redis not ready', async () => {
    const service = buildService();
    redisInstance.isReady = false;

    await expect(service.ensureReady()).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('re-checks readiness via ping and toggles ready flag', async () => {
    const service = buildService();
    await service.onModuleInit();
    mockPing.mockRejectedValueOnce(new Error('down'));

    await expect(service.ensureReady()).rejects.toBeInstanceOf(ServiceUnavailableException);

    redisInstance.isReady = true;
    mockPing.mockResolvedValueOnce('PONG');
    await expect(service.ensureReady()).resolves.toBeUndefined();
  });

  it('issues token and stores serialized state with TTL', async () => {
    const service = buildService();
    await service.onModuleInit();

    const token = await service.issueToken(sampleState, 3600);

    expect(typeof token).toBe('string');
    expect(mockSet).toHaveBeenCalledTimes(1);
    const [key, value, options] = mockSet.mock.calls[0];
    expect(key).toMatch(/^rt:\{[0-9a-f]{64}\}$/);
    expect(JSON.parse(value)).toEqual(sampleState);
    expect(options).toEqual({ EX: 3600 });
  });

  it('consumes token by reading and deleting redis key', async () => {
    const service = buildService();
    await service.onModuleInit();
    mockGet.mockResolvedValueOnce(JSON.stringify(sampleState));
    mockDel.mockResolvedValueOnce(1);

    const result = await service.consumeToken('token-123');

    expect(result).toEqual(sampleState);
    expect(mockDel).toHaveBeenCalledTimes(1);
  });

  it('returns null when consumeToken misses key', async () => {
    const service = buildService();
    await service.onModuleInit();
    mockGet.mockResolvedValueOnce(null);

    await expect(service.consumeToken('missing')).resolves.toBeNull();
    expect(mockDel).not.toHaveBeenCalled();
  });

  it('revokes token and reports deletion result', async () => {
    const service = buildService();
    await service.onModuleInit();
    mockDel.mockResolvedValueOnce(2);

    await expect(service.revokeToken('token')).resolves.toBe(true);
    mockDel.mockResolvedValueOnce(0);
    await expect(service.revokeToken('token2')).resolves.toBe(false);
  });

  it('quits redis connection on module destroy', async () => {
    const service = buildService();
    await service.onModuleInit();

    await service.onModuleDestroy();
    expect(mockQuit).toHaveBeenCalledTimes(1);
  });
});
