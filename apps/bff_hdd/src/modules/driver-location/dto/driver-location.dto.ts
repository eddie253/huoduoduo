import { IsNotEmpty, IsNumberString, IsOptional, IsString, MaxLength } from 'class-validator';

export class DriverLocationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  trackingNo!: string;

  @IsNumberString()
  @MaxLength(32)
  lat!: string;

  @IsNumberString()
  @MaxLength(32)
  lng!: string;

  @IsOptional()
  @IsNumberString()
  @MaxLength(16)
  accuracyMeters?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  recordedAt?: string;
}
