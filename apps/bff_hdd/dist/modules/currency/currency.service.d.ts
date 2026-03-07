import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthClaims } from '../../security/auth-claims';
import { CurrencyListResponseDto } from './dto/currency-response.dto';
export declare class CurrencyService {
    private readonly legacySoapClient;
    constructor(legacySoapClient: LegacySoapClient);
    getDaily(date: string, claims: AuthClaims): Promise<CurrencyListResponseDto>;
    getMonthly(date: string, claims: AuthClaims): Promise<CurrencyListResponseDto>;
    getBalance(claims: AuthClaims): Promise<CurrencyListResponseDto>;
    getDepositHead(startDate: string, endDate: string, claims: AuthClaims): Promise<CurrencyListResponseDto>;
    getDepositBody(tnum: string, address: string, claims: AuthClaims): Promise<CurrencyListResponseDto>;
    getShipmentCurrency(orderNum: string): Promise<CurrencyListResponseDto>;
}
