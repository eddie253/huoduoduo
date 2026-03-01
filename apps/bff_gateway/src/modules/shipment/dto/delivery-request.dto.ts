import { IsNotEmpty, IsNumberString, IsOptional, IsString } from 'class-validator';

export class DeliveryRequestDto {
  @IsOptional()
  @IsString()
  driverId?: string;

  @IsString()
  @IsNotEmpty()
  imageBase64!: string;

  @IsString()
  @IsNotEmpty()
  imageFileName!: string;

  @IsString()
  @IsOptional()
  signatureBase64?: string;

  @IsNumberString()
  latitude!: string;

  @IsNumberString()
  longitude!: string;
}
