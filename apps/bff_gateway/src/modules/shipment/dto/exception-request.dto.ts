import { IsNotEmpty, IsNumberString, IsOptional, IsString } from 'class-validator';

export class ExceptionRequestDto {
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
  @IsNotEmpty()
  reasonCode!: string;

  @IsOptional()
  @IsString()
  reasonMessage?: string;

  @IsNumberString()
  latitude!: string;

  @IsNumberString()
  longitude!: string;
}
