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
