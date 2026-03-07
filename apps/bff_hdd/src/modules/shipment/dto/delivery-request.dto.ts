import { IsNotEmpty, IsNumberString, IsOptional, IsString, MaxLength } from 'class-validator';

export class DeliveryRequestDto {
  @IsOptional()
  @IsString()
  @MaxLength(64)
  driverId?: string;

  @IsString()
  @IsNotEmpty()
  imageBase64!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  imageFileName!: string;

  @IsString()
  @IsOptional()
  signatureBase64?: string;

  @IsNumberString()
  @MaxLength(32)
  latitude!: string;

  @IsNumberString()
  @MaxLength(32)
  longitude!: string;
}
