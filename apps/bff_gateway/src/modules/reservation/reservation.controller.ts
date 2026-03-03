import { Body, Controller, Delete, Get, HttpCode, Param, Post, Query, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationParamDto } from './dto/reservation-param.dto';
import { DeleteReservationQueryDto, ReservationQueryDto } from './dto/reservation-query.dto';
import { ReservationResponseDto } from './dto/reservation-response.dto';
import { ReservationService } from './reservation.service';
import { NoStoreResponse } from '../../security/no-store-response.decorator';

@NoStoreResponse()
@Controller('reservations')
export class ReservationController {
  constructor(private readonly reservationService: ReservationService) {}

  @Get()
  listReservations(
    @Req() request: Request,
    @Query() query: ReservationQueryDto
  ): Promise<ReservationResponseDto[]> {
    const claims = (request as Request & { user: AuthClaims }).user;
    const mode = query.mode ?? 'standard';
    return this.reservationService.listReservations(mode, claims);
  }

  @Post()
  @HttpCode(200)
  createReservation(
    @Req() request: Request,
    @Query() query: ReservationQueryDto,
    @Body() dto: CreateReservationDto
  ): Promise<{ reservationNo: string; mode: 'standard' | 'bulk' }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    const mode = query.mode ?? 'standard';
    return this.reservationService.createReservation(mode, dto, claims);
  }

  @Delete(':id')
  deleteReservation(
    @Req() request: Request,
    @Param() param: ReservationParamDto,
    @Query() query: DeleteReservationQueryDto
  ): Promise<{ ok: boolean }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    const mode = query.mode ?? 'standard';
    return this.reservationService.deleteReservation(mode, param.id, query.address, claims);
  }
}
