import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { AuthClaims } from '../../security/auth-claims';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationService } from './reservation.service';

describe('ReservationService contract enforcement', () => {
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

  it('returns reservation list when response fields are within limits', async () => {
    const legacySoapClient = {
      listReservations: jest.fn(async () => [
        {
          reservationNo: 'R001',
          address: 'Addr',
          fee: null,
          shipmentNos: ['T001'],
          mode: 'standard' as const
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new ReservationService(legacySoapClient);
    const result = await service.listReservations('standard', claims);
    expect(result.length).toBe(1);
    expect(result[0].reservationNo).toBe('R001');
  });

  it('rejects over-length reservation response fields', async () => {
    const legacySoapClient = {
      listReservations: jest.fn(async () => [
        {
          reservationNo: `R${'1'.repeat(64)}`,
          address: 'Addr',
          fee: null,
          shipmentNos: ['T001'],
          mode: 'standard' as const
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new ReservationService(legacySoapClient);
    await expect(service.listReservations('standard', claims)).rejects.toMatchObject<
      Partial<LegacySoapError>
    >({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });

  it('enforces create/delete request fields and create response contract', async () => {
    const legacySoapClient = {
      createReservation: jest.fn(async () => ({
        reservationNo: `R${'1'.repeat(64)}`,
        mode: 'standard' as const
      })),
      deleteReservation: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;

    const service = new ReservationService(legacySoapClient);
    const createDto: CreateReservationDto = {
      address: 'Addr',
      shipmentNos: ['T001']
    };

    await expect(service.createReservation('standard', createDto, claims)).rejects.toMatchObject<
      Partial<LegacySoapError>
    >({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });

    await expect(
      service.deleteReservation('standard', `R${'1'.repeat(64)}`, 'Addr', claims)
    ).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });
});
