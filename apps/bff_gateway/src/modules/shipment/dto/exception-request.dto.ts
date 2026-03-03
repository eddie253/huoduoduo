import { IsNotEmpty, IsNumberString, IsOptional, IsString, MaxLength } from 'class-validator';

export class ExceptionRequestDto {
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
  @IsNotEmpty()
  @MaxLength(64)
  reasonCode!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1024)
  reasonMessage?: string;

  @IsNumberString()
  @MaxLength(32)
  latitude!: string;

  @IsNumberString()
  @MaxLength(32)
  longitude!: string;
}
