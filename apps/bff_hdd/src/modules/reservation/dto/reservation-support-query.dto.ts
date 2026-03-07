import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ReservationSupportZipQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  zip!: string;
}
