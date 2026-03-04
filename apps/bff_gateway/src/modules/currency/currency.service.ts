import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { P1_CONTRACT_LIMITS, ensureMax } from '../../core/contracts/p1-contract-policy';
import { P6_CONTRACT_LIMITS, enforceCurrencyListContract } from '../../core/contracts/p6-contract-policy';
import { AuthClaims } from '../../security/auth-claims';
import { CurrencyListResponseDto } from './dto/currency-response.dto';

@Injectable()
export class CurrencyService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  async getDaily(date: string, claims: AuthClaims): Promise<CurrencyListResponseDto> {
    const normalizedDate = ensureMax('currency.daily.request.date', date, P6_CONTRACT_LIMITS.date);
    const normalizedContractNo = ensureMax(
      'currency.daily.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const rows = await this.legacySoapClient.getDriverCurrency(normalizedDate, normalizedContractNo);
    return { items: enforceCurrencyListContract(rows, 'currency.daily.response') };
  }

  async getMonthly(date: string, claims: AuthClaims): Promise<CurrencyListResponseDto> {
    const normalizedDate = ensureMax('currency.monthly.request.date', date, P6_CONTRACT_LIMITS.date);
    const normalizedContractNo = ensureMax(
      'currency.monthly.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const rows = await this.legacySoapClient.getDriverCurrencyMonth(normalizedDate, normalizedContractNo);
    return { items: enforceCurrencyListContract(rows, 'currency.monthly.response') };
  }

  async getBalance(claims: AuthClaims): Promise<CurrencyListResponseDto> {
    const normalizedContractNo = ensureMax(
      'currency.balance.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const rows = await this.legacySoapClient.getDriverBalance(normalizedContractNo);
    return { items: enforceCurrencyListContract(rows, 'currency.balance.response') };
  }

  async getDepositHead(
    startDate: string,
    endDate: string,
    claims: AuthClaims
  ): Promise<CurrencyListResponseDto> {
    const normalizedStartDate = ensureMax(
      'currency.deposit.head.request.startDate',
      startDate,
      P6_CONTRACT_LIMITS.startDate
    );
    const normalizedEndDate = ensureMax(
      'currency.deposit.head.request.endDate',
      endDate,
      P6_CONTRACT_LIMITS.endDate
    );
    const normalizedContractNo = ensureMax(
      'currency.deposit.head.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const rows = await this.legacySoapClient.getDepositHead(
      normalizedStartDate,
      normalizedEndDate,
      normalizedContractNo
    );
    return { items: enforceCurrencyListContract(rows, 'currency.deposit.head.response') };
  }

  async getDepositBody(tnum: string, address: string, claims: AuthClaims): Promise<CurrencyListResponseDto> {
    const normalizedTnum = ensureMax('currency.deposit.body.request.tnum', tnum, P6_CONTRACT_LIMITS.tnum);
    const normalizedAddress = ensureMax(
      'currency.deposit.body.request.address',
      address,
      P6_CONTRACT_LIMITS.address
    );
    const normalizedContractNo = ensureMax(
      'currency.deposit.body.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const rows = await this.legacySoapClient.getDepositBody(
      normalizedTnum,
      normalizedAddress,
      normalizedContractNo
    );
    return { items: enforceCurrencyListContract(rows, 'currency.deposit.body.response') };
  }

  async getShipmentCurrency(orderNum: string): Promise<CurrencyListResponseDto> {
    const normalizedOrderNum = ensureMax(
      'currency.shipment.request.orderNum',
      orderNum,
      P6_CONTRACT_LIMITS.orderNum
    );
    const rows = await this.legacySoapClient.getShipmentCurrency(normalizedOrderNum);
    return { items: enforceCurrencyListContract(rows, 'currency.shipment.response') };
  }
}
