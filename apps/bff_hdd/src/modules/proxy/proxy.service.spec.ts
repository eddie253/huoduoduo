import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { ProxyService } from './proxy.service';

describe('ProxyService contract enforcement', () => {
  it('returns proxy mates when response fields are within limits', async () => {
    const legacySoapClient = {
      getProxyMates: jest.fn(async () => [
        {
          code: 'P001',
          name: 'Mate',
          area: 'A1',
          status: 'active',
          service: 'proxy',
          role: null,
          message: null,
          updatedAt: '2026-03-04T00:00:00Z'
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new ProxyService(legacySoapClient);
    const result = await service.getMates('A1');
    expect(result.items.length).toBe(1);
    expect(result.items[0].code).toBe('P001');
  });

  it('rejects over-length structural fields in proxy KPI response', async () => {
    const legacySoapClient = {
      getProxyKpi: jest.fn(async () => [
        {
          code: `C${'1'.repeat(64)}`,
          name: 'KPI',
          status: null,
          service: null,
          role: null,
          message: null,
          updatedAt: null
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new ProxyService(legacySoapClient);
    await expect(service.getKpi('2026', '03', 'A1')).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });

  it('truncates over-length proxy message field to 1024', async () => {
    const legacySoapClient = {
      searchProxyKpi: jest.fn(async () => [
        {
          code: 'K001',
          name: 'KPI Search',
          status: null,
          service: null,
          role: null,
          message: 'm'.repeat(1200),
          updatedAt: null
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new ProxyService(legacySoapClient);
    const result = await service.searchKpi('2026', '03', 'A1');
    expect(result.items[0].message?.length).toBe(1024);
  });
});
