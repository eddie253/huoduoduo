import { ConfigService } from '@nestjs/config';
import { SoapTransportService } from './soap-transport.service';
import { LegacySoapClient } from './legacy-soap.client';

describe('LegacySoapClient reservation mode mapping', () => {
  const makeClient = () => {
    const transport = {
      call: jest.fn(async ({ method }) => {
        if (
          method === 'GetARVed' ||
          method === 'GetBARVed' ||
          method === 'GetPxymate' ||
          method === 'SearchKPI' ||
          method === 'GetKPI' ||
          method === 'GetKPI_dis' ||
          method === 'GetDriverCurrency' ||
          method === 'GetDriverCurrencyMonth' ||
          method === 'GetDriverBalance' ||
          method === 'GetDeposit_Head' ||
          method === 'GetDeposit_Body' ||
          method === 'GetShipment_Currency' ||
          method === 'GetARV_ZIP' ||
          method === 'GetARV' ||
          method === 'GetAreaCode' ||
          method === 'GetArrived' ||
          method === 'GetBARV'
        ) {
          return '[]';
        }
        if (method === 'GetVersion') {
          return '123';
        }
        return 'OK';
      })
    } as unknown as SoapTransportService;
    const config = {
      get: jest.fn((_key: string, fallback: unknown) => fallback)
    } as unknown as ConfigService;
    return {
      client: new LegacySoapClient(transport, config),
      transport
    };
  };

  it('maps list reservations to correct SOAP methods', async () => {
    const { client, transport } = makeClient();
    await client.listReservations('standard', 'D001');
    await client.listReservations('bulk', 'D001');

    expect((transport.call as jest.Mock).mock.calls[0][0].method).toBe('GetARVed');
    expect((transport.call as jest.Mock).mock.calls[1][0].method).toBe('GetBARVed');
  });

  it('maps create reservation to correct SOAP methods', async () => {
    const { client, transport } = makeClient();
    await client.createReservation('standard', {
      contractNo: 'D001',
      address: 'addr',
      shipmentNos: ['T1', 'T2']
    });
    await client.createReservation('bulk', {
      contractNo: 'D001',
      address: 'addr',
      shipmentNos: ['T3'],
      fee: 120
    });

    expect((transport.call as jest.Mock).mock.calls[0][0].method).toBe('UpdateARV');
    expect((transport.call as jest.Mock).mock.calls[1][0].method).toBe('UpdateBARV');
  });

  it('P5_MAPPING_TRACEABILITY_4_OF_4 maps proxy/kpi endpoints to the correct SOAP methods', async () => {
    const { client, transport } = makeClient();
    await client.getProxyMates('A1');
    await client.searchProxyKpi('2026', '03', 'A1');
    await client.getProxyKpi('2026', '03', 'A1');
    await client.getProxyKpiDaily('2026-03-04', 'A1');

    expect((transport.call as jest.Mock).mock.calls[0][0].method).toBe('GetPxymate');
    expect((transport.call as jest.Mock).mock.calls[1][0].method).toBe('SearchKPI');
    expect((transport.call as jest.Mock).mock.calls[2][0].method).toBe('GetKPI');
    expect((transport.call as jest.Mock).mock.calls[3][0].method).toBe('GetKPI_dis');
  });

  it('P6_CURRENCY_MAPPING_TRACEABILITY_6_OF_6 maps currency endpoints to the correct SOAP methods', async () => {
    const { client, transport } = makeClient();
    await client.getDriverCurrency('2026-03-04', 'D001');
    await client.getDriverCurrencyMonth('2026-03', 'D001');
    await client.getDriverBalance('D001');
    await client.getDepositHead('2026-03-01', '2026-03-31', 'D001');
    await client.getDepositBody('T001', 'Addr', 'D001');
    await client.getShipmentCurrency('T001');

    expect((transport.call as jest.Mock).mock.calls[0][0].method).toBe('GetDriverCurrency');
    expect((transport.call as jest.Mock).mock.calls[1][0].method).toBe('GetDriverCurrencyMonth');
    expect((transport.call as jest.Mock).mock.calls[2][0].method).toBe('GetDriverBalance');
    expect((transport.call as jest.Mock).mock.calls[3][0].method).toBe('GetDeposit_Head');
    expect((transport.call as jest.Mock).mock.calls[4][0].method).toBe('GetDeposit_Body');
    expect((transport.call as jest.Mock).mock.calls[5][0].method).toBe('GetShipment_Currency');
  });

  it('P7_RESERVATION_WEB_API_MAPPING_TRACEABILITY_5_OF_5 maps reservation support endpoints to SOAP methods', async () => {
    const { client, transport } = makeClient();
    await client.getReservationZipAreas();
    await client.getReservationAvailable('100', 'D001');
    await client.getReservationAreaCodes('D001');
    await client.getReservationArrived('D001');
    await client.getReservationAvailableBulk('100', 'D001');

    expect((transport.call as jest.Mock).mock.calls[0][0].method).toBe('GetARV_ZIP');
    expect((transport.call as jest.Mock).mock.calls[1][0].method).toBe('GetARV');
    expect((transport.call as jest.Mock).mock.calls[2][0].method).toBe('GetAreaCode');
    expect((transport.call as jest.Mock).mock.calls[3][0].method).toBe('GetArrived');
    expect((transport.call as jest.Mock).mock.calls[4][0].method).toBe('GetBARV');
  });

  it('P9_MAPPING_TRACEABILITY_2_OF_2 maps unregister/version endpoints to SOAP methods', async () => {
    const { client, transport } = makeClient();
    await client.deleteRegId('D001', 'token-1');
    await client.getVersion('DirverAPP');

    expect((transport.call as jest.Mock).mock.calls[0][0].method).toBe('DeleteRegID');
    expect((transport.call as jest.Mock).mock.calls[1][0].method).toBe('GetVersion');
  });
});

describe('LegacySoapClient validateLogin branches', () => {
  const makeErrorClient = (responseMap: Record<string, string>) => {
    const transport = {
      call: jest.fn(async ({ method }: { method: string }) => responseMap[method] ?? 'OK')
    } as unknown as SoapTransportService;
    const config = {
      get: jest.fn((_key: string, fallback: unknown) => fallback)
    } as unknown as ConfigService;
    return { client: new LegacySoapClient(transport, config), transport };
  };

  it('returns null when GetLogin response is empty array', async () => {
    const { client } = makeErrorClient({ GetLogin: '[]' });
    const result = await client.validateLogin('user', 'pass');
    expect(result).toBeNull();
  });

  it('returns LegacyUser when response contains 契約編號', async () => {
    const { client } = makeErrorClient({
      GetLogin: JSON.stringify([{ '契約編號': 'D001', '姓名': 'Driver', '代理區域職位': 'driver' }])
    });
    const result = await client.validateLogin('driver', 'pass');
    expect(result).toMatchObject({ id: 'D001', contractNo: 'D001', account: 'driver', displayName: 'Driver', role: 'driver' });
  });

  it('uses DNUM key as fallback for contractNo', async () => {
    const { client } = makeErrorClient({
      GetLogin: JSON.stringify([{ DNUM: 'D002' }])
    });
    const result = await client.validateLogin('driver2', 'pass');
    expect(result?.contractNo).toBe('D002');
  });

  it('defaults displayName to account when 姓名 is missing', async () => {
    const { client } = makeErrorClient({
      GetLogin: JSON.stringify([{ '契約編號': 'D003' }])
    });
    const result = await client.validateLogin('myaccount', 'pass');
    expect(result?.displayName).toBe('myaccount');
  });

  it('defaults role to "driver" when 代理區域職位 is missing', async () => {
    const { client } = makeErrorClient({
      GetLogin: JSON.stringify([{ '契約編號': 'D004', '姓名': 'X' }])
    });
    const result = await client.validateLogin('acc', 'pass');
    expect(result?.role).toBe('driver');
  });

  it('throws LEGACY_BAD_RESPONSE when contractNo is missing from row', async () => {
    const { client } = makeErrorClient({
      GetLogin: JSON.stringify([{ '姓名': 'NoContract' }])
    });
    await expect(client.validateLogin('user', 'pass')).rejects.toMatchObject({
      code: 'LEGACY_BAD_RESPONSE', statusCode: 502
    });
  });

  it('throws LEGACY_BUSINESS_ERROR on "Error" prefixed response', async () => {
    const { client } = makeErrorClient({ GetLogin: 'Error: invalid credentials' });
    await expect(client.validateLogin('user', 'pass')).rejects.toMatchObject({
      code: 'LEGACY_BUSINESS_ERROR', statusCode: 422
    });
  });

});

describe('LegacySoapClient listReservations branches', () => {
  it('throws LEGACY_BAD_RESPONSE when list response is not valid JSON', async () => {
    const transport = {
      call: jest.fn(async ({ method }: { method: string }) => ({ GetARVed: 'broken{{json' } as Record<string, string>)[method] ?? 'OK')
    } as unknown as SoapTransportService;
    const config = {
      get: jest.fn((_key: string, fallback: unknown) => fallback)
    } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);
    await expect(client.listReservations('standard', 'D001')).rejects.toMatchObject({
      code: 'LEGACY_BAD_RESPONSE', statusCode: 502
    });
  });
});

describe('LegacySoapClient buildWebviewCookies', () => {
  it('returns three cookies using fallback domain from WEBVIEW_BASE_URL', async () => {
    const transport = { call: jest.fn(async () => 'OK') } as unknown as SoapTransportService;
    const config = { get: jest.fn((_key: string, fallback: unknown) => fallback) } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);

    const cookies = await client.buildWebviewCookies('account-1', 'id-token-1');
    expect(cookies).toHaveLength(3);
    expect(cookies[0].name).toBe('Account');
    expect(cookies[0].value).toBe('account-1');
    expect(cookies[1].name).toBe('Identify');
    expect(cookies[1].value).toBe('id-token-1');
    expect(cookies[2].name).toBe('Kind');
    expect(cookies[2].value).toBe('android');
    expect(cookies.every((c) => c.secure)).toBe(true);
    expect(cookies.every((c) => c.path === '/')).toBe(true);
  });

  it('uses WEBVIEW_COOKIE_DOMAIN config when provided', async () => {
    const transport = { call: jest.fn(async () => 'OK') } as unknown as SoapTransportService;
    const config = {
      get: jest.fn((key: string, fallback: unknown) => {
        if (key === 'WEBVIEW_COOKIE_DOMAIN') return 'custom.domain.com';
        return fallback;
      })
    } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);

    const cookies = await client.buildWebviewCookies('acc', 'id');
    expect(cookies[0].domain).toBe('custom.domain.com');
  });
});

describe('LegacySoapClient getBulletins', () => {
  const makeClient = (raw: string) => {
    const transport = { call: jest.fn(async () => raw) } as unknown as SoapTransportService;
    const config = { get: jest.fn((_k: string, fb: unknown) => fb) } as unknown as ConfigService;
    return new LegacySoapClient(transport, config);
  };

  it('returns empty array when response is null string', async () => {
    const client = makeClient('null');
    expect(await client.getBulletins()).toEqual([]);
  });

  it('maps bulletin records with 公告標題 field', async () => {
    const client = makeClient(JSON.stringify([
      { UID: 'U1', '公告標題': 'Announcement', '公告日期': '2026-03' }
    ]));
    const result = await client.getBulletins();
    expect(result).toHaveLength(1);
    expect(result[0].title).toBe('Announcement');
    expect(result[0].uid).toBe('U1');
    expect(result[0].date).toBe('2026-03');
  });

  it('filters out records with blank title', async () => {
    const client = makeClient(JSON.stringify([{ UID: 'U2', '公告標題': '   ' }]));
    expect(await client.getBulletins()).toHaveLength(0);
  });

  it('throws LEGACY_BUSINESS_ERROR when response starts with Error', async () => {
    const client = makeClient('Error: bulletin fetch failed');
    await expect(client.getBulletins()).rejects.toMatchObject({ code: 'LEGACY_BUSINESS_ERROR' });
  });
});

describe('LegacySoapClient getShipment fallback logic', () => {
  it('throws LEGACY_BUSINESS_ERROR when GetShipment_elf returns business error', async () => {
    const transport = {
      call: jest.fn(async ({ method }: { method: string }) => {
        if (method === 'GetShipment_elf') return 'Error: not found';
        return '[]';
      })
    } as unknown as SoapTransportService;
    const config = { get: jest.fn((_k: string, fb: unknown) => fb) } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);
    await expect(client.getShipment('T001')).rejects.toMatchObject({ code: 'LEGACY_BUSINESS_ERROR', statusCode: 422 });
  });

  it('falls back to GetShipment when GetShipment_elf returns empty', async () => {
    const transport = {
      call: jest.fn(async ({ method }: { method: string }) => {
        if (method === 'GetShipment_elf') return '[]';
        if (method === 'GetShipment') {
          return JSON.stringify([{
            '查件貨號': 'T999', '收件人': 'Bob', '地址': 'Addr',
            '電話': '', '手機': '', '郵遞區號': '', '縣市': '', '地區': '',
            '配送狀態': 'delivered'
          }]);
        }
        return '[]';
      })
    } as unknown as SoapTransportService;
    const config = { get: jest.fn((_k: string, fb: unknown) => fb) } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);
    const result = await client.getShipment('T999');
    expect(result.trackingNo).toBe('T999');
    expect(result.recipient).toBe('Bob');
  });

  it('throws LEGACY_BAD_RESPONSE when both SOAP methods return empty', async () => {
    const transport = { call: jest.fn(async () => '[]') } as unknown as SoapTransportService;
    const config = { get: jest.fn((_k: string, fb: unknown) => fb) } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);
    await expect(client.getShipment('T000')).rejects.toMatchObject({ code: 'LEGACY_BAD_RESPONSE', statusCode: 502 });
  });
});

describe('LegacySoapClient updateRegId', () => {
  it('calls UpdateRegID with all params', async () => {
    const transport = { call: jest.fn(async () => 'OK') } as unknown as SoapTransportService;
    const config = { get: jest.fn((_k: string, fb: unknown) => fb) } as unknown as ConfigService;
    const client = new LegacySoapClient(transport, config);

    await client.updateRegId('D001', 'reg-token', 'Android', 2);
    expect((transport.call as jest.Mock).mock.calls[0][0]).toMatchObject({
      method: 'UpdateRegID',
      params: { DNUM: 'D001', RegID: 'reg-token', Kind: 'Android', Version: '2' }
    });
  });
});
