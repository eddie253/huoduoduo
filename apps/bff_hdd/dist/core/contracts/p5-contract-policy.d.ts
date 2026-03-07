import { ProxyKpiRecord, ProxyMateRecord } from '../../adapters/soap/legacy-soap.client';
export declare const P5_CONTRACT_LIMITS: {
    readonly area: 64;
    readonly year: 4;
    readonly month: 2;
    readonly date: 10;
    readonly code: 64;
    readonly status: 64;
    readonly role: 64;
    readonly name: 128;
    readonly service: 128;
    readonly message: 1024;
    readonly datetime: 40;
};
export declare function enforceProxyMateListContract(items: ProxyMateRecord[], fieldPrefix?: string): ProxyMateRecord[];
export declare function enforceProxyKpiListContract(items: ProxyKpiRecord[], fieldPrefix?: string): ProxyKpiRecord[];
