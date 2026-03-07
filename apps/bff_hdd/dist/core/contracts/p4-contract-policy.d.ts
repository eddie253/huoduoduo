export declare const P4_CONTRACT_LIMITS: {
    readonly errorCode: 64;
    readonly errorMessage: 1024;
    readonly healthStatus: 32;
    readonly healthService: 64;
    readonly datetime: 40;
};
export interface ErrorResponseContract {
    code: string;
    message: string;
}
export interface HealthResponseContract {
    status: string;
    service: string;
    timestamp: string;
}
export declare function enforceHealthResponseContract(payload: HealthResponseContract, fieldPrefix?: string): HealthResponseContract;
export declare function normalizeErrorResponseContract(code: string | null | undefined, message: string | null | undefined): ErrorResponseContract;
