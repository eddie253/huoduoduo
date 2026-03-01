import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class ReservationQueryDto {
  @IsOptional()
  @IsIn(['standard', 'bulk'])
  mode?: 'standard' | 'bulk';
}

export class DeleteReservationQueryDto extends ReservationQueryDto {
  @IsString()
  @IsNotEmpty()
  address!: string;
}
