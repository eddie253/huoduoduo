import { ProxyAreaQueryDto, ProxyKpiDailyQueryDto, ProxyKpiQueryDto } from './dto/proxy-query.dto';
import { ProxyKpiListResponseDto, ProxyMateListResponseDto } from './dto/proxy-response.dto';
import { ProxyService } from './proxy.service';
export declare class ProxyController {
    private readonly proxyService;
    constructor(proxyService: ProxyService);
    getMates(query: ProxyAreaQueryDto): Promise<ProxyMateListResponseDto>;
    searchKpi(query: ProxyKpiQueryDto): Promise<ProxyKpiListResponseDto>;
    getKpi(query: ProxyKpiQueryDto): Promise<ProxyKpiListResponseDto>;
    getKpiDaily(query: ProxyKpiDailyQueryDto): Promise<ProxyKpiListResponseDto>;
}
