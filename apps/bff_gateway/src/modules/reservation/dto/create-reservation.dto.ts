import { ArrayNotEmpty, IsArray, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateReservationDto {
  @IsOptional()
  @IsString()
  areaCode?: string;

  @IsString()
  @IsNotEmpty()
  address!: string;

  @IsOptional()
  @IsNumber()
  fee?: number;

  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  shipmentNos!: string[];

  @IsOptional()
  @IsString()
  note?: string;
}
