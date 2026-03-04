import { Controller, Get, Query, Req } from '@nestjs/common';
import { Request } from 'express';
import { NoStoreResponse } from '../../security/no-store-response.decorator';
import { AuthClaims } from '../../security/auth-claims';
import {
  CurrencyDateQueryDto,
  CurrencyDepositBodyQueryDto,
  CurrencyDepositHeadQueryDto,
  CurrencyShipmentQueryDto
} from './dto/currency-query.dto';
import { CurrencyListResponseDto } from './dto/currency-response.dto';
import { CurrencyService } from './currency.service';

@NoStoreResponse()
@Controller('currency')
export class CurrencyController {
  constructor(private readonly currencyService: CurrencyService) {}

  @Get('daily')
  getDaily(@Req() request: Request, @Query() query: CurrencyDateQueryDto): Promise<CurrencyListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.currencyService.getDaily(query.date, claims);
  }

  @Get('monthly')
  getMonthly(@Req() request: Request, @Query() query: CurrencyDateQueryDto): Promise<CurrencyListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.currencyService.getMonthly(query.date, claims);
  }

  @Get('balance')
  getBalance(@Req() request: Request): Promise<CurrencyListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.currencyService.getBalance(claims);
  }

  @Get('deposit/head')
  getDepositHead(
    @Req() request: Request,
    @Query() query: CurrencyDepositHeadQueryDto
  ): Promise<CurrencyListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.currencyService.getDepositHead(query.startDate, query.endDate, claims);
  }

  @Get('deposit/body')
  getDepositBody(
    @Req() request: Request,
    @Query() query: CurrencyDepositBodyQueryDto
  ): Promise<CurrencyListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.currencyService.getDepositBody(query.tnum, query.address, claims);
  }

  @Get('shipment')
  getShipmentCurrency(@Query() query: CurrencyShipmentQueryDto): Promise<CurrencyListResponseDto> {
    return this.currencyService.getShipmentCurrency(query.orderNum);
  }
}
