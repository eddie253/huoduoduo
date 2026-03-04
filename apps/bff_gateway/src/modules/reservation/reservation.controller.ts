import { Body, Controller, Delete, Get, HttpCode, Param, Post, Query, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationSupportZipQueryDto } from './dto/reservation-support-query.dto';
import { ReservationSupportListResponseDto } from './dto/reservation-support-response.dto';
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

  @Get('zip-areas')
  getZipAreas(): Promise<ReservationSupportListResponseDto> {
    return this.reservationService.getZipAreas();
  }

  @Get('available')
  getAvailable(
    @Req() request: Request,
    @Query() query: ReservationSupportZipQueryDto
  ): Promise<ReservationSupportListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.reservationService.getAvailable(query.zip, claims);
  }

  @Get('available/bulk')
  getAvailableBulk(
    @Req() request: Request,
    @Query() query: ReservationSupportZipQueryDto
  ): Promise<ReservationSupportListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.reservationService.getAvailableBulk(query.zip, claims);
  }

  @Get('area-codes')
  getAreaCodes(@Req() request: Request): Promise<ReservationSupportListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.reservationService.getAreaCodes(claims);
  }

  @Get('arrived')
  getArrived(@Req() request: Request): Promise<ReservationSupportListResponseDto> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.reservationService.getArrived(claims);
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
