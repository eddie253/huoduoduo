import type { Request } from 'express';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationSupportZipQueryDto } from './dto/reservation-support-query.dto';
import { ReservationSupportListResponseDto } from './dto/reservation-support-response.dto';
import { ReservationParamDto } from './dto/reservation-param.dto';
import { DeleteReservationQueryDto, ReservationQueryDto } from './dto/reservation-query.dto';
import { ReservationResponseDto } from './dto/reservation-response.dto';
import { ReservationService } from './reservation.service';
export declare class ReservationController {
    private readonly reservationService;
    constructor(reservationService: ReservationService);
    listReservations(request: Request, query: ReservationQueryDto): Promise<ReservationResponseDto[]>;
    getZipAreas(): Promise<ReservationSupportListResponseDto>;
    getAvailable(request: Request, query: ReservationSupportZipQueryDto): Promise<ReservationSupportListResponseDto>;
    getAvailableBulk(request: Request, query: ReservationSupportZipQueryDto): Promise<ReservationSupportListResponseDto>;
    getAreaCodes(request: Request): Promise<ReservationSupportListResponseDto>;
    getArrived(request: Request): Promise<ReservationSupportListResponseDto>;
    createReservation(request: Request, query: ReservationQueryDto, dto: CreateReservationDto): Promise<{
        reservationNo: string;
        mode: 'standard' | 'bulk';
    }>;
    deleteReservation(request: Request, param: ReservationParamDto, query: DeleteReservationQueryDto): Promise<{
        ok: boolean;
    }>;
}
