import { IsNotEmpty, IsString, Matches, MaxLength } from 'class-validator';

export class ProxyAreaQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  area!: string;
}

export class ProxyKpiQueryDto extends ProxyAreaQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4)
  @Matches(/^\d{4}$/)
  year!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2)
  @Matches(/^\d{1,2}$/)
  month!: string;
}

export class ProxyKpiDailyQueryDto extends ProxyAreaQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(10)
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date!: string;
}
