import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength
} from 'class-validator';

export class CreateReservationDto {
  @IsOptional()
  @IsString()
  @MaxLength(64)
  areaCode?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  address!: string;

  @IsOptional()
  @IsNumber()
  fee?: number;

  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(200)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  shipmentNos!: string[];

  @IsOptional()
  @IsString()
  @MaxLength(1024)
  note?: string;
}
