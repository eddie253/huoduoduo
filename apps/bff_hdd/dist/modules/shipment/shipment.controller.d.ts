import type { Request } from 'express';
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentResponseDto } from './dto/shipment-response.dto';
import { ShipmentService } from './shipment.service';
export declare class ShipmentController {
    private readonly shipmentService;
    constructor(shipmentService: ShipmentService);
    getShipment(trackingNo: string): Promise<ShipmentResponseDto>;
    submitDelivery(request: Request, trackingNo: string, dto: DeliveryRequestDto, idempotencyKey?: string): Promise<{
        ok: boolean;
    }>;
    submitException(request: Request, trackingNo: string, dto: ExceptionRequestDto, idempotencyKey?: string): Promise<{
        ok: boolean;
    }>;
}
