import { ConflictException, Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import {
  P1_CONTRACT_LIMITS,
  ensureMax
} from '../../core/contracts/p1-contract-policy';
import {
  P2_CONTRACT_LIMITS,
  enforceShipmentResponseContract
} from '../../core/contracts/p2-contract-policy';
import { AuthClaims } from '../../security/auth-claims';
import { IdempotencyGuardService } from '../../shared/idempotency/idempotency-guard.service';
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentResponseDto } from './dto/shipment-response.dto';

@Injectable()
export class ShipmentService {
  constructor(
    private readonly legacySoapClient: LegacySoapClient,
    private readonly idempotencyGuardService: IdempotencyGuardService
  ) {}

  async getShipment(trackingNo: string): Promise<ShipmentResponseDto> {
    const normalizedTrackingNo = ensureMax(
      'shipments.get.request.trackingNo',
      trackingNo,
      P2_CONTRACT_LIMITS.trackingNo
    );
    const shipment = await this.legacySoapClient.getShipment(normalizedTrackingNo);
    return enforceShipmentResponseContract(shipment);
  }

  async submitDelivery(
    trackingNo: string,
    dto: DeliveryRequestDto,
    claims: AuthClaims,
    idempotencyKey?: string
  ): Promise<{ ok: boolean }> {
    const normalizedTrackingNo = ensureMax(
      'shipments.delivery.request.trackingNo',
      trackingNo,
      P2_CONTRACT_LIMITS.trackingNo
    );
    const normalizedContractNo = ensureMax(
      'shipments.delivery.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );

    if (idempotencyKey) {
      const accepted = await this.idempotencyGuardService.ensureUnique(
        `delivery:${normalizedTrackingNo}`,
        idempotencyKey,
        60 * 60 * 24
      );
      if (!accepted) {
        throw new ConflictException({ code: 'DELIVERY_DUPLICATE' });
      }
    }

    if (dto.signatureBase64) {
      await this.legacySoapClient.uploadSignature(normalizedTrackingNo, {
        contractNo: normalizedContractNo,
        signatureBase64: dto.signatureBase64
      });
    }

    await this.legacySoapClient.submitShipmentDelivery(normalizedTrackingNo, {
      contractNo: normalizedContractNo,
      imageBase64: dto.imageBase64,
      imageFileName: dto.imageFileName,
      latitude: dto.latitude,
      longitude: dto.longitude
    });
    return { ok: true };
  }

  async submitException(
    trackingNo: string,
    dto: ExceptionRequestDto,
    claims: AuthClaims,
    idempotencyKey?: string
  ): Promise<{ ok: boolean }> {
    const normalizedTrackingNo = ensureMax(
      'shipments.exception.request.trackingNo',
      trackingNo,
      P2_CONTRACT_LIMITS.trackingNo
    );
    const normalizedContractNo = ensureMax(
      'shipments.exception.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );

    if (idempotencyKey) {
      const accepted = await this.idempotencyGuardService.ensureUnique(
        `exception:${normalizedTrackingNo}`,
        idempotencyKey,
        60 * 60 * 24
      );
      if (!accepted) {
        throw new ConflictException({ code: 'DELIVERY_DUPLICATE' });
      }
    }

    await this.legacySoapClient.submitShipmentException(normalizedTrackingNo, {
      contractNo: normalizedContractNo,
      imageBase64: dto.imageBase64,
      imageFileName: dto.imageFileName,
      latitude: dto.latitude,
      longitude: dto.longitude
    });
    return { ok: true };
  }
}
