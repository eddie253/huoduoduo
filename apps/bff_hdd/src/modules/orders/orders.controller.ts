import { Controller, HttpCode, Param, Post, Req, Headers } from '@nestjs/common';
import type { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { OrdersService } from './orders.service';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post(':trackingNo/accept')
  @HttpCode(200)
  acceptOrder(
    @Req() request: Request,
    @Param('trackingNo') trackingNo: string,
    @Headers('x-idempotency-key') idempotencyKey: string
  ): Promise<{ ok: boolean }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.ordersService.acceptOrder(trackingNo, claims, idempotencyKey);
  }
}
