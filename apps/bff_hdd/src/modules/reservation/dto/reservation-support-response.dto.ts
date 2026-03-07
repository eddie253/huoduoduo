export class ReservationSupportItemDto {
  code!: string;
  name!: string;
  status!: string | null;
  service!: string | null;
  role!: string | null;
  message!: string | null;
  reservationNo!: string | null;
  trackingNo!: string | null;
  zip!: string | null;
  areaCode!: string | null;
  address!: string | null;
  date!: string | null;
}

export class ReservationSupportListResponseDto {
  items!: ReservationSupportItemDto[];
}
