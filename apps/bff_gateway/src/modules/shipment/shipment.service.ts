import { Injectable } from '@nestjs/common';
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
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentResponseDto } from './dto/shipment-response.dto';

@Injectable()
export class ShipmentService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

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
    claims: AuthClaims
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
    claims: AuthClaims
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
