import { ensureIsoDatetime, ensureMax, truncateMax } from './p1-contract-policy';

export const P4_CONTRACT_LIMITS = {
  errorCode: 64,
  errorMessage: 1024,
  healthStatus: 32,
  healthService: 64,
  datetime: 40
} as const;

export interface ErrorResponseContract {
  code: string;
  message: string;
}

export interface HealthResponseContract {
  status: string;
  service: string;
  timestamp: string;
}

export function enforceHealthResponseContract(
  payload: HealthResponseContract,
  fieldPrefix = 'health.response'
): HealthResponseContract {
  const status = ensureMax(
    `${fieldPrefix}.status`,
    payload.status,
    P4_CONTRACT_LIMITS.healthStatus
  );
  const service = ensureMax(
    `${fieldPrefix}.service`,
    payload.service,
    P4_CONTRACT_LIMITS.healthService
  );
  const timestamp =
    ensureIsoDatetime(
      `${fieldPrefix}.timestamp`,
      payload.timestamp,
      P4_CONTRACT_LIMITS.datetime
    ) || new Date(0).toISOString();

  return {
    status,
    service,
    timestamp
  };
}

export function normalizeErrorResponseContract(
  code: string | null | undefined,
  message: string | null | undefined
): ErrorResponseContract {
  const safeCode = normalizeCode(code);
  const safeMessage = normalizeMessage(message);
  return {
    code: safeCode,
    message: safeMessage
  };
}

function normalizeCode(code: string | null | undefined): string {
  const normalized = String(code ?? '').trim();
  if (!normalized) {
    return 'INTERNAL_SERVER_ERROR';
  }
  if (normalized.length > P4_CONTRACT_LIMITS.errorCode) {
    return 'INTERNAL_SERVER_ERROR';
  }
  return normalized;
}

function normalizeMessage(message: string | null | undefined): string {
  const normalized = String(message ?? '').trim();
  if (!normalized) {
    return 'Internal server error.';
  }
  return truncateMax(normalized, P4_CONTRACT_LIMITS.errorMessage);
}
