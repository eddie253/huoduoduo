import type { Request } from 'express';
import { CurrencyDateQueryDto, CurrencyDepositBodyQueryDto, CurrencyDepositHeadQueryDto, CurrencyShipmentQueryDto } from './dto/currency-query.dto';
import { CurrencyListResponseDto } from './dto/currency-response.dto';
import { CurrencyService } from './currency.service';
export declare class CurrencyController {
    private readonly currencyService;
    constructor(currencyService: CurrencyService);
    getDaily(request: Request, query: CurrencyDateQueryDto): Promise<CurrencyListResponseDto>;
    getMonthly(request: Request, query: CurrencyDateQueryDto): Promise<CurrencyListResponseDto>;
    getBalance(request: Request): Promise<CurrencyListResponseDto>;
    getDepositHead(request: Request, query: CurrencyDepositHeadQueryDto): Promise<CurrencyListResponseDto>;
    getDepositBody(request: Request, query: CurrencyDepositBodyQueryDto): Promise<CurrencyListResponseDto>;
    getShipmentCurrency(query: CurrencyShipmentQueryDto): Promise<CurrencyListResponseDto>;
}
