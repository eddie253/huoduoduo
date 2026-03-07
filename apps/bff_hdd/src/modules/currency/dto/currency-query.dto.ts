import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CurrencyDateQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  date!: string;
}

export class CurrencyDepositHeadQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  startDate!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  endDate!: string;
}

export class CurrencyDepositBodyQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  tnum!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  address!: string;
}

export class CurrencyShipmentQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  orderNum!: string;
}
