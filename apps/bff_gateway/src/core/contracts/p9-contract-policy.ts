import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { ensureMax } from './p1-contract-policy';

export const P9_CONTRACT_LIMITS = {
  regId: 4096,
  datetime: 40,
  versionName: 64,
  versionRaw: 64
} as const;

export interface SystemVersionResponseContract {
  name: string;
  versionCode: number;
}

export function enforceSystemVersionResponseContract(
  payload: SystemVersionResponseContract,
  fieldPrefix = 'system.version.response'
): SystemVersionResponseContract {
  return {
    name: ensureMax(`${fieldPrefix}.name`, payload.name, P9_CONTRACT_LIMITS.versionName),
    versionCode: ensureVersionCode(`${fieldPrefix}.versionCode`, payload.versionCode)
  };
}

export function parseLegacyVersionCode(raw: string, fieldPrefix = 'system.version.response'): number {
  const normalizedRaw = ensureMax(
    `${fieldPrefix}.raw`,
    String(raw).trim(),
    P9_CONTRACT_LIMITS.versionRaw
  );
  if (!normalizedRaw) {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw is empty.`);
  }

  const direct = normalizeVersionToken(normalizedRaw);
  if (direct != null) {
    return direct;
  }

  // Legacy payload might occasionally be JSON-wrapped; accept single value extraction only.
  try {
    const parsed = JSON.parse(normalizedRaw) as unknown;
    const candidate = extractVersionCandidate(parsed);
    if (candidate == null) {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw has no version token.`);
    }
    const fromJson = normalizeVersionToken(candidate);
    if (fromJson == null) {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw is not a valid version code.`);
    }
    return fromJson;
  } catch (error) {
    if (error instanceof LegacySoapError) {
      throw error;
    }
    throw new LegacySoapError(
      'LEGACY_BAD_RESPONSE',
      502,
      `${fieldPrefix}.raw is not a valid numeric version payload.`
    );
  }
}

function ensureVersionCode(field: string, value: number): number {
  if (!Number.isInteger(value) || value < 0) {
    throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be a non-negative integer.`);
  }
  return value;
}

function normalizeVersionToken(input: string): number | null {
  const normalized = input.trim().replace(/^"+|"+$/g, '');
  if (!/^\d+$/.test(normalized)) {
    return null;
  }
  const numeric = Number(normalized);
  if (!Number.isSafeInteger(numeric) || numeric < 0) {
    return null;
  }
  return numeric;
}

function extractVersionCandidate(parsed: unknown): string | null {
  if (typeof parsed === 'string') {
    return parsed;
  }
  if (typeof parsed === 'number' && Number.isFinite(parsed)) {
    return String(parsed);
  }
  if (Array.isArray(parsed) && parsed.length > 0) {
    return extractVersionCandidate(parsed[0]);
  }
  if (parsed && typeof parsed === 'object') {
    const record = parsed as Record<string, unknown>;
    const keys = ['Version', 'version', 'VersionCode', 'versionCode', 'Code', 'code', 'Value', 'value'];
    for (const key of keys) {
      const value = record[key];
      if (typeof value === 'string' || typeof value === 'number') {
        return String(value);
      }
    }
    const firstScalar = Object.values(record).find(
      (value) => typeof value === 'string' || typeof value === 'number'
    );
    if (firstScalar != null) {
      return String(firstScalar);
    }
  }
  return null;
}
