import { CurrencyRecord } from '../../adapters/soap/legacy-soap.client';
export declare const P6_CONTRACT_LIMITS: {
    readonly date: 40;
    readonly startDate: 40;
    readonly endDate: 40;
    readonly tnum: 64;
    readonly orderNum: 64;
    readonly address: 512;
    readonly code: 64;
    readonly name: 128;
    readonly status: 64;
    readonly service: 128;
    readonly role: 64;
    readonly message: 1024;
    readonly currency: 16;
    readonly datetime: 40;
    readonly orderNo: 64;
};
export declare function enforceCurrencyListContract(items: CurrencyRecord[], fieldPrefix?: string): CurrencyRecord[];
