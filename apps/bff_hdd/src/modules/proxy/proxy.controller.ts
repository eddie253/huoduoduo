import { Controller, Get, Query } from '@nestjs/common';
import { NoStoreResponse } from '../../security/no-store-response.decorator';
import { ProxyAreaQueryDto, ProxyKpiDailyQueryDto, ProxyKpiQueryDto } from './dto/proxy-query.dto';
import { ProxyKpiListResponseDto, ProxyMateListResponseDto } from './dto/proxy-response.dto';
import { ProxyService } from './proxy.service';

@NoStoreResponse()
@Controller('proxy')
export class ProxyController {
  constructor(private readonly proxyService: ProxyService) {}

  @Get('mates')
  getMates(@Query() query: ProxyAreaQueryDto): Promise<ProxyMateListResponseDto> {
    return this.proxyService.getMates(query.area);
  }

  @Get('kpi/search')
  searchKpi(@Query() query: ProxyKpiQueryDto): Promise<ProxyKpiListResponseDto> {
    return this.proxyService.searchKpi(query.year, query.month, query.area);
  }

  @Get('kpi')
  getKpi(@Query() query: ProxyKpiQueryDto): Promise<ProxyKpiListResponseDto> {
    return this.proxyService.getKpi(query.year, query.month, query.area);
  }

  @Get('kpi/daily')
  getKpiDaily(@Query() query: ProxyKpiDailyQueryDto): Promise<ProxyKpiListResponseDto> {
    return this.proxyService.getKpiDaily(query.date, query.area);
  }
}
