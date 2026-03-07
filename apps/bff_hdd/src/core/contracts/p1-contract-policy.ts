import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';

export const P1_CONTRACT_LIMITS = {
  token: 4096,
  refreshToken: 1024,
  userId: 64,
  contractNo: 64,
  userName: 128,
  role: 32,
  url: 2048,
  cookieCount: 20,
  cookieName: 64,
  cookieValue: 4096,
  cookieDomain: 255,
  cookiePath: 255,
  bulletinMessage: 2000,
  datetime: 40,
  subject: 64,
  deviceId: 64,
  platform: 16,
  fcmToken: 4096
} as const;

export function ensureMax(field: string, value: string, max: number): string {
  if (value.length > max) {
    throw new LegacySoapError(
      'LEGACY_BAD_RESPONSE',
      502,
      `${field} exceeds max length ${max}.`
    );
  }
  return value;
}

export function ensureOptionalMax(
  field: string,
  value: string | null | undefined,
  max: number
): string | null {
  if (value == null) {
    return null;
  }
  return ensureMax(field, value, max);
}

export function ensureMaxItems(field: string, count: number, max: number): void {
  if (count > max) {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} exceeds max items ${max}.`);
  }
}

export function truncateMax(value: string, max: number): string {
  if (value.length <= max) {
    return value;
  }
  return value.slice(0, max);
}

export function ensureIsoDatetime(field: string, value: string | null, max: number): string | null {
  if (value == null) {
    return null;
  }
  const normalized = ensureMax(field, value, max);
  const parsed = Date.parse(normalized);
  if (Number.isNaN(parsed)) {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} is not a valid ISO datetime.`);
  }
  return normalized;
}
