import { IsIn, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class LoginRequestDto {
  @IsString()
  @IsNotEmpty()
  account!: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  password!: string;

  @IsString()
  @IsNotEmpty()
  deviceId!: string;

  @IsIn(['android', 'ios'])
  platform!: 'android' | 'ios';
}
