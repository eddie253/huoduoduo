import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthClaims } from '../../security/auth-claims';
import { IdempotencyGuardService } from '../../shared/idempotency/idempotency-guard.service';
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentResponseDto } from './dto/shipment-response.dto';
export declare class ShipmentService {
    private readonly legacySoapClient;
    private readonly idempotencyGuardService;
    constructor(legacySoapClient: LegacySoapClient, idempotencyGuardService: IdempotencyGuardService);
    getShipment(trackingNo: string): Promise<ShipmentResponseDto>;
    submitDelivery(trackingNo: string, dto: DeliveryRequestDto, claims: AuthClaims, idempotencyKey?: string): Promise<{
        ok: boolean;
    }>;
    submitException(trackingNo: string, dto: ExceptionRequestDto, claims: AuthClaims, idempotencyKey?: string): Promise<{
        ok: boolean;
    }>;
}
