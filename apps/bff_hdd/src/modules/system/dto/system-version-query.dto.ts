import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class SystemVersionQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  name!: string;
}
