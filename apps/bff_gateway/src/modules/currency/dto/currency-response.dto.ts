export class CurrencyItemDto {
  code!: string;
  name!: string;
  status!: string | null;
  service!: string | null;
  role!: string | null;
  message!: string | null;
  currency!: string | null;
  orderNo!: string | null;
  address!: string | null;
  date!: string | null;
  amount!: number | null;
  balance!: number | null;
}

export class CurrencyListResponseDto {
  items!: CurrencyItemDto[];
}
