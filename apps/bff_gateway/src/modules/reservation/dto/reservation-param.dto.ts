import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ReservationParamDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  id!: string;
}
