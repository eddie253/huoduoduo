import { IsOptional, IsString, MaxLength } from 'class-validator';

export class LogoutRequestDto {
  @IsOptional()
  @IsString()
  @MaxLength(1024)
  refreshToken?: string;
}
