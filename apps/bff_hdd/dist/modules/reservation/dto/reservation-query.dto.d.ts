export declare class ReservationQueryDto {
    mode?: 'standard' | 'bulk';
}
export declare class DeleteReservationQueryDto extends ReservationQueryDto {
    address: string;
}
