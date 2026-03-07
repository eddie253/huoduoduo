import { ShipmentResponseDto } from '../../modules/shipment/dto/shipment-response.dto';
import { ensureMax, ensureOptionalMax } from './p1-contract-policy';

export const P2_CONTRACT_LIMITS = {
  trackingNo: 32,
  recipient: 128,
  address: 512,
  phone: 32,
  mobile: 32,
  zipCode: 16,
  city: 64,
  district: 64,
  status: 64,
  signedAt: 40,
  signedImageFileName: 255,
  signedLocation: 64
} as const;

export function enforceShipmentResponseContract(
  shipment: ShipmentResponseDto,
  fieldPrefix = 'shipments.get.response'
): ShipmentResponseDto {
  return {
    trackingNo: ensureMax(
      `${fieldPrefix}.trackingNo`,
      shipment.trackingNo,
      P2_CONTRACT_LIMITS.trackingNo
    ),
    recipient: ensureMax(
      `${fieldPrefix}.recipient`,
      shipment.recipient,
      P2_CONTRACT_LIMITS.recipient
    ),
    address: ensureMax(`${fieldPrefix}.address`, shipment.address, P2_CONTRACT_LIMITS.address),
    phone: ensureMax(`${fieldPrefix}.phone`, shipment.phone, P2_CONTRACT_LIMITS.phone),
    mobile: ensureMax(`${fieldPrefix}.mobile`, shipment.mobile, P2_CONTRACT_LIMITS.mobile),
    zipCode: ensureMax(`${fieldPrefix}.zipCode`, shipment.zipCode, P2_CONTRACT_LIMITS.zipCode),
    city: ensureMax(`${fieldPrefix}.city`, shipment.city, P2_CONTRACT_LIMITS.city),
    district: ensureMax(`${fieldPrefix}.district`, shipment.district, P2_CONTRACT_LIMITS.district),
    status: ensureMax(`${fieldPrefix}.status`, shipment.status, P2_CONTRACT_LIMITS.status),
    signedAt: ensureOptionalMax(
      `${fieldPrefix}.signedAt`,
      shipment.signedAt,
      P2_CONTRACT_LIMITS.signedAt
    ),
    signedImageFileName: ensureOptionalMax(
      `${fieldPrefix}.signedImageFileName`,
      shipment.signedImageFileName,
      P2_CONTRACT_LIMITS.signedImageFileName
    ),
    signedLocation: ensureOptionalMax(
      `${fieldPrefix}.signedLocation`,
      shipment.signedLocation,
      P2_CONTRACT_LIMITS.signedLocation
    )
  };
}
