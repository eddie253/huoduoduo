import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { ensureMax, ensureMaxItems } from './p1-contract-policy';

export const P3_CONTRACT_LIMITS = {
  reservationNo: 64,
  address: 512,
  shipmentNo: 64,
  shipmentNosMaxItems: 200,
  mode: 16,
  areaCode: 64,
  note: 1024
} as const;

export interface ReservationContractItem {
  reservationNo: string;
  address: string;
  fee: number | null;
  shipmentNos: string[];
  mode: 'standard' | 'bulk';
}

export function enforceReservationListContract(
  reservations: ReservationContractItem[],
  fieldPrefix = 'reservations.list.response'
): ReservationContractItem[] {
  return reservations.map((item, index) =>
    enforceReservationItemContract(item, `${fieldPrefix}[${index}]`)
  );
}

export function enforceReservationCreateContract(
  result: { reservationNo: string; mode: 'standard' | 'bulk' },
  fieldPrefix = 'reservations.create.response'
): { reservationNo: string; mode: 'standard' | 'bulk' } {
  const reservationNo = ensureMax(
    `${fieldPrefix}.reservationNo`,
    result.reservationNo,
    P3_CONTRACT_LIMITS.reservationNo
  );
  const mode = ensureReservationMode(result.mode, `${fieldPrefix}.mode`);
  return {
    reservationNo,
    mode
  };
}

function enforceReservationItemContract(
  item: ReservationContractItem,
  fieldPrefix: string
): ReservationContractItem {
  ensureMaxItems(
    `${fieldPrefix}.shipmentNos`,
    item.shipmentNos.length,
    P3_CONTRACT_LIMITS.shipmentNosMaxItems
  );

  return {
    reservationNo: ensureMax(
      `${fieldPrefix}.reservationNo`,
      item.reservationNo,
      P3_CONTRACT_LIMITS.reservationNo
    ),
    address: ensureMax(`${fieldPrefix}.address`, item.address, P3_CONTRACT_LIMITS.address),
    fee: ensureReservationFee(item.fee, `${fieldPrefix}.fee`),
    shipmentNos: item.shipmentNos.map((shipmentNo, index) =>
      ensureMax(
        `${fieldPrefix}.shipmentNos[${index}]`,
        shipmentNo,
        P3_CONTRACT_LIMITS.shipmentNo
      )
    ),
    mode: ensureReservationMode(item.mode, `${fieldPrefix}.mode`)
  };
}

function ensureReservationMode(
  mode: string,
  field: string
): 'standard' | 'bulk' {
  ensureMax(field, mode, P3_CONTRACT_LIMITS.mode);
  if (mode !== 'standard' && mode !== 'bulk') {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} invalid value: ${mode}`);
  }
  return mode;
}

function ensureReservationFee(
  fee: number | null,
  field: string
): number | null {
  if (fee == null) {
    return null;
  }
  if (typeof fee !== 'number' || Number.isNaN(fee)) {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be number or null.`);
  }
  return fee;
}
