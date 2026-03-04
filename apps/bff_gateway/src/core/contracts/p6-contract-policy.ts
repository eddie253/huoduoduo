import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { CurrencyRecord } from '../../adapters/soap/legacy-soap.client';
import { ensureMax, ensureOptionalMax, truncateMax } from './p1-contract-policy';

export const P6_CONTRACT_LIMITS = {
  date: 40,
  startDate: 40,
  endDate: 40,
  tnum: 64,
  orderNum: 64,
  address: 512,
  code: 64,
  name: 128,
  status: 64,
  service: 128,
  role: 64,
  message: 1024,
  currency: 16,
  datetime: 40,
  orderNo: 64
} as const;

export function enforceCurrencyListContract(
  items: CurrencyRecord[],
  fieldPrefix = 'currency.response'
): CurrencyRecord[] {
  return items.map((item, index) => ({
    code: ensureMax(`${fieldPrefix}[${index}].code`, item.code, P6_CONTRACT_LIMITS.code),
    name: ensureMax(`${fieldPrefix}[${index}].name`, item.name, P6_CONTRACT_LIMITS.name),
    status: ensureOptionalMax(`${fieldPrefix}[${index}].status`, item.status, P6_CONTRACT_LIMITS.status),
    service: ensureOptionalMax(
      `${fieldPrefix}[${index}].service`,
      item.service,
      P6_CONTRACT_LIMITS.service
    ),
    role: ensureOptionalMax(`${fieldPrefix}[${index}].role`, item.role, P6_CONTRACT_LIMITS.role),
    message:
      item.message == null ? null : truncateMax(item.message, P6_CONTRACT_LIMITS.message),
    currency: ensureOptionalMax(
      `${fieldPrefix}[${index}].currency`,
      item.currency,
      P6_CONTRACT_LIMITS.currency
    ),
    orderNo: ensureOptionalMax(
      `${fieldPrefix}[${index}].orderNo`,
      item.orderNo,
      P6_CONTRACT_LIMITS.orderNo
    ),
    address: ensureOptionalMax(
      `${fieldPrefix}[${index}].address`,
      item.address,
      P6_CONTRACT_LIMITS.address
    ),
    date: ensureOptionalMax(`${fieldPrefix}[${index}].date`, item.date, P6_CONTRACT_LIMITS.datetime),
    amount: ensureOptionalNumber(`${fieldPrefix}[${index}].amount`, item.amount),
    balance: ensureOptionalNumber(`${fieldPrefix}[${index}].balance`, item.balance)
  }));
}

function ensureOptionalNumber(field: string, value: number | null): number | null {
  if (value == null) {
    return null;
  }
  if (typeof value !== 'number' || Number.isNaN(value)) {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be number or null.`);
  }
  return value;
}
