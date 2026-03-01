import { IsIn, IsNotEmpty, IsString } from 'class-validator';
import { IsInt, IsOptional, Min } from 'class-validator';

export class RegisterPushTokenDto {
  @IsString()
  @IsNotEmpty()
  deviceId!: string;

  @IsIn(['android', 'ios'])
  platform!: 'android' | 'ios';

  @IsString()
  @IsNotEmpty()
  fcmToken!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  appVersion?: number;
}
