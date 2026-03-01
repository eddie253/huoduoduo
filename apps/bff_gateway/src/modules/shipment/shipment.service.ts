import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthClaims } from '../../security/auth-claims';
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentResponseDto } from './dto/shipment-response.dto';

@Injectable()
export class ShipmentService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  getShipment(trackingNo: string): Promise<ShipmentResponseDto> {
    return this.legacySoapClient.getShipment(trackingNo);
  }

  async submitDelivery(
    trackingNo: string,
    dto: DeliveryRequestDto,
    claims: AuthClaims
  ): Promise<{ ok: boolean }> {
    await this.legacySoapClient.submitShipmentDelivery(trackingNo, {
      contractNo: claims.contractNo,
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
    await this.legacySoapClient.submitShipmentException(trackingNo, {
      contractNo: claims.contractNo,
      imageBase64: dto.imageBase64,
      imageFileName: dto.imageFileName,
      latitude: dto.latitude,
      longitude: dto.longitude
    });
    return { ok: true };
  }
}
