import { ShipmentResponseDto } from '../../modules/shipment/dto/shipment-response.dto';
export declare const P2_CONTRACT_LIMITS: {
    readonly trackingNo: 32;
    readonly recipient: 128;
    readonly address: 512;
    readonly phone: 32;
    readonly mobile: 32;
    readonly zipCode: 16;
    readonly city: 64;
    readonly district: 64;
    readonly status: 64;
    readonly signedAt: 40;
    readonly signedImageFileName: 255;
    readonly signedLocation: 64;
};
export declare function enforceShipmentResponseContract(shipment: ShipmentResponseDto, fieldPrefix?: string): ShipmentResponseDto;
