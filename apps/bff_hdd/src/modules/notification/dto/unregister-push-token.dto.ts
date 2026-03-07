import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UnregisterPushTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  fcmToken!: string;
}
