import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { ensureMax } from '../../core/contracts/p1-contract-policy';
import {
  P5_CONTRACT_LIMITS,
  enforceProxyKpiListContract,
  enforceProxyMateListContract
} from '../../core/contracts/p5-contract-policy';
import { ProxyKpiListResponseDto, ProxyMateListResponseDto } from './dto/proxy-response.dto';

@Injectable()
export class ProxyService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  async getMates(area: string): Promise<ProxyMateListResponseDto> {
    const normalizedArea = ensureMax('proxy.mates.request.area', area, P5_CONTRACT_LIMITS.area);
    const rows = await this.legacySoapClient.getProxyMates(normalizedArea);
    return {
      items: enforceProxyMateListContract(rows)
    };
  }

  async searchKpi(year: string, month: string, area: string): Promise<ProxyKpiListResponseDto> {
    const normalizedYear = ensureMax('proxy.kpi.search.request.year', year, P5_CONTRACT_LIMITS.year);
    const normalizedMonth = ensureMax('proxy.kpi.search.request.month', month, P5_CONTRACT_LIMITS.month);
    const normalizedArea = ensureMax('proxy.kpi.search.request.area', area, P5_CONTRACT_LIMITS.area);
    const rows = await this.legacySoapClient.searchProxyKpi(normalizedYear, normalizedMonth, normalizedArea);
    return {
      items: enforceProxyKpiListContract(rows, 'proxy.kpi.search.response')
    };
  }

  async getKpi(year: string, month: string, area: string): Promise<ProxyKpiListResponseDto> {
    const normalizedYear = ensureMax('proxy.kpi.request.year', year, P5_CONTRACT_LIMITS.year);
    const normalizedMonth = ensureMax('proxy.kpi.request.month', month, P5_CONTRACT_LIMITS.month);
    const normalizedArea = ensureMax('proxy.kpi.request.area', area, P5_CONTRACT_LIMITS.area);
    const rows = await this.legacySoapClient.getProxyKpi(normalizedYear, normalizedMonth, normalizedArea);
    return {
      items: enforceProxyKpiListContract(rows, 'proxy.kpi.response')
    };
  }

  async getKpiDaily(date: string, area: string): Promise<ProxyKpiListResponseDto> {
    const normalizedDate = ensureMax('proxy.kpi.daily.request.date', date, P5_CONTRACT_LIMITS.date);
    const normalizedArea = ensureMax('proxy.kpi.daily.request.area', area, P5_CONTRACT_LIMITS.area);
    const rows = await this.legacySoapClient.getProxyKpiDaily(normalizedDate, normalizedArea);
    return {
      items: enforceProxyKpiListContract(rows, 'proxy.kpi.daily.response')
    };
  }
}
