import { Controller, Get, Query } from '@nestjs/common';
import { NoStoreResponse } from '../../security/no-store-response.decorator';
import { Public } from '../../security/public.decorator';
import { SystemVersionQueryDto } from './dto/system-version-query.dto';
import { SystemVersionResponseDto } from './dto/system-version-response.dto';
import { SystemService } from './system.service';

@NoStoreResponse()
@Controller('system')
export class SystemController {
  constructor(private readonly systemService: SystemService) {}

  @Public()
  @Get('version')
  getVersion(@Query() query: SystemVersionQueryDto): Promise<SystemVersionResponseDto> {
    return this.systemService.getVersion(query.name);
  }
}
