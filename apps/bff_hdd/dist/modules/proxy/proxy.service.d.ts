import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { ProxyKpiListResponseDto, ProxyMateListResponseDto } from './dto/proxy-response.dto';
export declare class ProxyService {
    private readonly legacySoapClient;
    constructor(legacySoapClient: LegacySoapClient);
    getMates(area: string): Promise<ProxyMateListResponseDto>;
    searchKpi(year: string, month: string, area: string): Promise<ProxyKpiListResponseDto>;
    getKpi(year: string, month: string, area: string): Promise<ProxyKpiListResponseDto>;
    getKpiDaily(date: string, area: string): Promise<ProxyKpiListResponseDto>;
}
