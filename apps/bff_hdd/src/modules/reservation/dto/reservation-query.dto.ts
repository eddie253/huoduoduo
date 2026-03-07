import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class ReservationQueryDto {
  @IsOptional()
  @IsIn(['standard', 'bulk'])
  mode?: 'standard' | 'bulk';
}

export class DeleteReservationQueryDto extends ReservationQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  address!: string;
}
