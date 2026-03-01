import { ConfigService } from '@nestjs/config';
import { SoapTransportService } from './soap-transport.service';
import { LegacySoapClient } from './legacy-soap.client';

describe('LegacySoapClient reservation mode mapping', () => {
  const makeClient = () => {
    const transport = {
      call: jest.fn(async ({ method }) => {
        if (method === 'GetARVed' || method === 'GetBARVed') {
          return '[]';
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
});
