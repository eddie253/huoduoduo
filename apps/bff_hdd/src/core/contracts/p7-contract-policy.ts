import { ReservationSupportRecord } from '../../adapters/soap/legacy-soap.client';
import { ensureMax, ensureOptionalMax, truncateMax } from './p1-contract-policy';

export const P7_CONTRACT_LIMITS = {
  zip: 64,
  code: 64,
  status: 64,
  role: 64,
  name: 128,
  service: 128,
  message: 1024,
  reservationNo: 64,
  trackingNo: 64,
  areaCode: 64,
  address: 512,
  datetime: 40
} as const;

export function enforceReservationSupportListContract(
  items: ReservationSupportRecord[],
  fieldPrefix = 'reservations.support.response'
): ReservationSupportRecord[] {
  return items.map((item, index) => ({
    code: ensureMax(`${fieldPrefix}[${index}].code`, item.code, P7_CONTRACT_LIMITS.code),
    name: ensureMax(`${fieldPrefix}[${index}].name`, item.name, P7_CONTRACT_LIMITS.name),
    status: ensureOptionalMax(`${fieldPrefix}[${index}].status`, item.status, P7_CONTRACT_LIMITS.status),
    service: ensureOptionalMax(
      `${fieldPrefix}[${index}].service`,
      item.service,
      P7_CONTRACT_LIMITS.service
    ),
    role: ensureOptionalMax(`${fieldPrefix}[${index}].role`, item.role, P7_CONTRACT_LIMITS.role),
    message:
      item.message == null ? null : truncateMax(item.message, P7_CONTRACT_LIMITS.message),
    reservationNo: ensureOptionalMax(
      `${fieldPrefix}[${index}].reservationNo`,
      item.reservationNo,
      P7_CONTRACT_LIMITS.reservationNo
    ),
    trackingNo: ensureOptionalMax(
      `${fieldPrefix}[${index}].trackingNo`,
      item.trackingNo,
      P7_CONTRACT_LIMITS.trackingNo
    ),
    zip: ensureOptionalMax(`${fieldPrefix}[${index}].zip`, item.zip, P7_CONTRACT_LIMITS.zip),
    areaCode: ensureOptionalMax(
      `${fieldPrefix}[${index}].areaCode`,
      item.areaCode,
      P7_CONTRACT_LIMITS.areaCode
    ),
    address: ensureOptionalMax(
      `${fieldPrefix}[${index}].address`,
      item.address,
      P7_CONTRACT_LIMITS.address
    ),
    date: ensureOptionalMax(`${fieldPrefix}[${index}].date`, item.date, P7_CONTRACT_LIMITS.datetime)
  }));
}
