export type LegacyErrorCode = 'LEGACY_TIMEOUT' | 'LEGACY_BAD_RESPONSE' | 'LEGACY_BUSINESS_ERROR';
export declare class LegacySoapError extends Error {
    readonly code: LegacyErrorCode;
    readonly statusCode: number;
    constructor(code: LegacyErrorCode, statusCode: number, message: string);
}
