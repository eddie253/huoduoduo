export type LegacyErrorCode =
  | 'LEGACY_TIMEOUT'
  | 'LEGACY_BAD_RESPONSE'
  | 'LEGACY_BUSINESS_ERROR';

export class LegacySoapError extends Error {
  constructor(
    public readonly code: LegacyErrorCode,
    public readonly statusCode: number,
    message: string
  ) {
    super(message);
  }
}
