import { CurrencyService } from './currency.service';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { AuthClaims } from '../../security/auth-claims';

describe('CurrencyService contract enforcement', () => {
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

  it('returns daily currency payload when fields are within limits', async () => {
    const legacySoapClient = {
      getDriverCurrency: jest.fn(async () => [
        {
          code: 'C001',
          name: 'Daily',
          status: 'ok',
          service: 'currency',
          role: null,
          message: null,
          currency: 'TWD',
          orderNo: null,
          address: null,
          date: '2026-03-04',
          amount: 100,
          balance: 1000
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new CurrencyService(legacySoapClient);
    const result = await service.getDaily('2026-03-04', claims);
    expect(result.items.length).toBe(1);
    expect(result.items[0].code).toBe('C001');
  });

  it('rejects over-length structural fields in response', async () => {
    const legacySoapClient = {
      getDriverCurrencyMonth: jest.fn(async () => [
        {
          code: `C${'1'.repeat(64)}`,
          name: 'Monthly',
          status: null,
          service: null,
          role: null,
          message: null,
          currency: null,
          orderNo: null,
          address: null,
          date: null,
          amount: null,
          balance: null
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new CurrencyService(legacySoapClient);
    await expect(service.getMonthly('2026-03', claims)).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });

  it('truncates over-length message field to 1024', async () => {
    const legacySoapClient = {
      getShipmentCurrency: jest.fn(async () => [
        {
          code: 'C001',
          name: 'Shipment',
          status: null,
          service: null,
          role: null,
          message: 'm'.repeat(1300),
          currency: null,
          orderNo: 'T001',
          address: null,
          date: null,
          amount: null,
          balance: null
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new CurrencyService(legacySoapClient);
    const result = await service.getShipmentCurrency('T001');
    expect(result.items[0].message?.length).toBe(1024);
  });
});

describe('CurrencyService additional branches', () => {
  const claims: AuthClaims = {
    sub: 'D001', account: 'driver', role: 'driver', contractNo: 'D001',
    identify: 'identify', platform: 'android', deviceId: 'device-1', jti: 'jti-1'
  };

  const makeRecord = (overrides: Partial<{
    code: string; name: string; status: string | null; service: string | null;
    role: string | null; message: string | null; currency: string | null;
    orderNo: string | null; address: string | null; date: string | null;
    amount: number | null; balance: number | null;
  }> = {}) => ({
    code: 'C001', name: 'Test', status: null, service: null, role: null,
    message: null, currency: null, orderNo: null, address: null,
    date: null, amount: null, balance: null, ...overrides
  });

  it('getDaily propagates LegacySoapError from SOAP client', async () => {
    const legacySoapClient = {
      getDriverCurrency: jest.fn(async () => { throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, 'fail'); })
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    await expect(service.getDaily('2026-03-04', claims)).rejects.toMatchObject({ code: 'LEGACY_BUSINESS_ERROR' });
  });

  it('getDaily returns empty items when SOAP returns empty array', async () => {
    const legacySoapClient = {
      getDriverCurrency: jest.fn(async () => [])
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    const result = await service.getDaily('2026-03-04', claims);
    expect(result.items).toHaveLength(0);
  });

  it('getMonthly propagates LegacySoapError from SOAP client', async () => {
    const legacySoapClient = {
      getDriverCurrencyMonth: jest.fn(async () => { throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, 'fail'); })
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    await expect(service.getMonthly('2026-03', claims)).rejects.toMatchObject({ code: 'LEGACY_BUSINESS_ERROR' });
  });

  it('getMonthly passes full data through when fields are valid', async () => {
    const legacySoapClient = {
      getDriverCurrencyMonth: jest.fn(async () => [
        makeRecord({ code: 'C001', name: 'Monthly', currency: 'TWD', amount: 500, balance: 5000 })
      ])
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    const result = await service.getMonthly('2026-03', claims);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].currency).toBe('TWD');
    expect(result.items[0].amount).toBe(500);
  });

  it('getShipmentCurrency propagates LegacySoapError', async () => {
    const legacySoapClient = {
      getShipmentCurrency: jest.fn(async () => { throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, 'fail'); })
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    await expect(service.getShipmentCurrency('T001')).rejects.toMatchObject({ code: 'LEGACY_BUSINESS_ERROR' });
  });

  it('getBalance returns items from getDriverBalance', async () => {
    const legacySoapClient = {
      getDriverBalance: jest.fn(async () => [
        makeRecord({ code: 'B001', name: 'Balance', balance: 9999 })
      ])
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    const result = await service.getBalance(claims);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].balance).toBe(9999);
  });

  it('getBalance propagates LegacySoapError', async () => {
    const legacySoapClient = {
      getDriverBalance: jest.fn(async () => { throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, 'fail'); })
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    await expect(service.getBalance(claims)).rejects.toMatchObject({ code: 'LEGACY_BUSINESS_ERROR' });
  });

  it('getDepositHead returns items from getDepositHead SOAP call', async () => {
    const legacySoapClient = {
      getDepositHead: jest.fn(async () => [
        makeRecord({ code: 'D001', name: 'Deposit', amount: 1000 })
      ])
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    const result = await service.getDepositHead('2026-03-01', '2026-03-31', claims);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].amount).toBe(1000);
  });

  it('getDepositBody returns items from getDepositBody SOAP call', async () => {
    const legacySoapClient = {
      getDepositBody: jest.fn(async () => [
        makeRecord({ code: 'D002', name: 'DepositBody', address: 'Addr' })
      ])
    } as unknown as LegacySoapClient;
    const service = new CurrencyService(legacySoapClient);
    const result = await service.getDepositBody('T001', 'Addr', claims);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].address).toBe('Addr');
  });
});
