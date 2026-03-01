import { Body, Controller, Get, HttpCode, Param, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { DeliveryRequestDto } from './dto/delivery-request.dto';
import { ExceptionRequestDto } from './dto/exception-request.dto';
import { ShipmentResponseDto } from './dto/shipment-response.dto';
import { ShipmentService } from './shipment.service';

@Controller('shipments')
export class ShipmentController {
  constructor(private readonly shipmentService: ShipmentService) {}

  @Get(':trackingNo')
  getShipment(@Param('trackingNo') trackingNo: string): Promise<ShipmentResponseDto> {
    return this.shipmentService.getShipment(trackingNo);
  }

  @Post(':trackingNo/delivery')
  @HttpCode(200)
  submitDelivery(
    @Req() request: Request,
    @Param('trackingNo') trackingNo: string,
    @Body() dto: DeliveryRequestDto
  ): Promise<{ ok: boolean }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.shipmentService.submitDelivery(trackingNo, dto, claims);
  }

  @Post(':trackingNo/exception')
  @HttpCode(200)
  submitException(
    @Req() request: Request,
    @Param('trackingNo') trackingNo: string,
    @Body() dto: ExceptionRequestDto
  ): Promise<{ ok: boolean }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.shipmentService.submitException(trackingNo, dto, claims);
  }
}
