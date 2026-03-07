import { ReservationSupportRecord } from '../../adapters/soap/legacy-soap.client';
export declare const P7_CONTRACT_LIMITS: {
    readonly zip: 64;
    readonly code: 64;
    readonly status: 64;
    readonly role: 64;
    readonly name: 128;
    readonly service: 128;
    readonly message: 1024;
    readonly reservationNo: 64;
    readonly trackingNo: 64;
    readonly areaCode: 64;
    readonly address: 512;
    readonly datetime: 40;
};
export declare function enforceReservationSupportListContract(items: ReservationSupportRecord[], fieldPrefix?: string): ReservationSupportRecord[];
