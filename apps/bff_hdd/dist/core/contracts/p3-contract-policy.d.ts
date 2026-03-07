export declare const P3_CONTRACT_LIMITS: {
    readonly reservationNo: 64;
    readonly address: 512;
    readonly shipmentNo: 64;
    readonly shipmentNosMaxItems: 200;
    readonly mode: 16;
    readonly areaCode: 64;
    readonly note: 1024;
};
export interface ReservationContractItem {
    reservationNo: string;
    address: string;
    fee: number | null;
    shipmentNos: string[];
    mode: 'standard' | 'bulk';
}
export declare function enforceReservationListContract(reservations: ReservationContractItem[], fieldPrefix?: string): ReservationContractItem[];
export declare function enforceReservationCreateContract(result: {
    reservationNo: string;
    mode: 'standard' | 'bulk';
}, fieldPrefix?: string): {
    reservationNo: string;
    mode: 'standard' | 'bulk';
};
