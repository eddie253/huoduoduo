export interface ReservationResponseDto {
    reservationNo: string;
    address: string;
    fee: number | null;
    shipmentNos: string[];
    mode: 'standard' | 'bulk';
}
