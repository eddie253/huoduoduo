import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RefreshRequestDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1024)
  refreshToken!: string;
}
