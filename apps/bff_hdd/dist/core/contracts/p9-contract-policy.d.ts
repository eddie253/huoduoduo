export declare const P9_CONTRACT_LIMITS: {
    readonly regId: 4096;
    readonly datetime: 40;
    readonly versionName: 64;
    readonly versionRaw: 64;
};
export interface SystemVersionResponseContract {
    name: string;
    versionCode: number;
}
export declare function enforceSystemVersionResponseContract(payload: SystemVersionResponseContract, fieldPrefix?: string): SystemVersionResponseContract;
export declare function parseLegacyVersionCode(raw: string, fieldPrefix?: string): number;
