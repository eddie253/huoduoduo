import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class RegisterPushTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  deviceId!: string;

  @IsIn(['android', 'ios'])
  @MaxLength(16)
  platform!: 'android' | 'ios';

  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  fcmToken!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  appVersion?: number;
}
