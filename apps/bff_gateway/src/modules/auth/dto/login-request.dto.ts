import { IsIn, IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class LoginRequestDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  account!: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  @MaxLength(128)
  password!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  deviceId!: string;

  @IsIn(['android', 'ios'])
  @MaxLength(16)
  platform!: 'android' | 'ios';
}
