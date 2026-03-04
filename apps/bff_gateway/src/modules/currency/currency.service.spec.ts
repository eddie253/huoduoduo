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
