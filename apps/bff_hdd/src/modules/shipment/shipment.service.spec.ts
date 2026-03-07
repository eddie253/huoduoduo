import { ConflictException } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { IdempotencyGuardService } from '../../shared/idempotency/idempotency-guard.service';
import { AuthClaims } from '../../security/auth-claims';
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentService } from './shipment.service';

describe('ShipmentService contract enforcement', () => {
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

  const idempotencyGuard = {
    ensureUnique: jest.fn(async () => true)
  } as unknown as IdempotencyGuardService;

  it('returns shipment payload when all fields are within contract limits', async () => {
    const legacySoapClient = {
      getShipment: jest.fn(async () => ({
        trackingNo: 'T001',
        recipient: 'Receiver',
        address: 'Somewhere',
        phone: '02-1234',
        mobile: '0912',
        zipCode: '100',
        city: 'Taipei',
        district: 'Da-an',
        status: 'PENDING',
        signedAt: null,
        signedImageFileName: null,
        signedLocation: null
      }))
    } as unknown as LegacySoapClient;

    const service = new ShipmentService(legacySoapClient, idempotencyGuard);
    const result = await service.getShipment('T001');
    expect(result.trackingNo).toBe('T001');
  });

  it('rejects shipment response when critical fields exceed limits', async () => {
    const legacySoapClient = {
      getShipment: jest.fn(async () => ({
        trackingNo: 'T001',
        recipient: 'R'.repeat(129),
        address: 'Somewhere',
        phone: '02-1234',
        mobile: '0912',
        zipCode: '100',
        city: 'Taipei',
        district: 'Da-an',
        status: 'PENDING',
        signedAt: null,
        signedImageFileName: null,
        signedLocation: null
      }))
    } as unknown as LegacySoapClient;

    const service = new ShipmentService(legacySoapClient, idempotencyGuard);
    await expect(service.getShipment('T001')).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });

  it('enforces request trackingNo/contractNo limits before delivery/exception submit', async () => {
    const legacySoapClient = {
      submitShipmentDelivery: jest.fn(async () => undefined),
      submitShipmentException: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;

    const service = new ShipmentService(legacySoapClient, idempotencyGuard);
    const deliveryDto: DeliveryRequestDto = {
      imageBase64: 'abc',
      imageFileName: 'proof.jpg',
      latitude: '25.03',
      longitude: '121.56'
    };
    const exceptionDto: ExceptionRequestDto = {
      imageBase64: 'abc',
      imageFileName: 'proof.jpg',
      reasonCode: 'E001',
      latitude: '25.03',
      longitude: '121.56'
    };

    await expect(
      service.submitDelivery(`T${'1'.repeat(32)}`, deliveryDto, claims)
    ).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });

    await expect(
      service.submitException(`T${'1'.repeat(32)}`, exceptionDto, claims)
    ).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });

  it('throws 409 for duplicate idempotency key on delivery', async () => {
    const legacySoapClient = {
      submitShipmentDelivery: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;
    const guard = {
      ensureUnique: jest.fn(async () => false)
    } as unknown as IdempotencyGuardService;
    const service = new ShipmentService(legacySoapClient, guard);

    const deliveryDto: DeliveryRequestDto = {
      imageBase64: 'abc',
      imageFileName: 'proof.jpg',
      latitude: '25.03',
      longitude: '121.56'
    };

    await expect(service.submitDelivery('T001', deliveryDto, claims, 'queue-1')).rejects.toBeInstanceOf(
      ConflictException
    );
  });

  it('uploads signature before delivery when signatureBase64 is present', async () => {
    const legacySoapClient = {
      uploadSignature: jest.fn(async () => undefined),
      submitShipmentDelivery: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;
    const guard = {
      ensureUnique: jest.fn(async () => true)
    } as unknown as IdempotencyGuardService;
    const service = new ShipmentService(legacySoapClient, guard);

    const deliveryDto: DeliveryRequestDto = {
      imageBase64: 'abc',
      imageFileName: 'proof.jpg',
      latitude: '25.03',
      longitude: '121.56',
      signatureBase64: 'signature'
    };

    await service.submitDelivery('T001', deliveryDto, claims, 'queue-2');

    expect(legacySoapClient.uploadSignature).toHaveBeenCalledTimes(1);
    expect(legacySoapClient.submitShipmentDelivery).toHaveBeenCalledTimes(1);
    expect(legacySoapClient.uploadSignature).toHaveBeenCalledWith('T001', {
      contractNo: 'D001',
      signatureBase64: 'signature'
    });
  });
});
