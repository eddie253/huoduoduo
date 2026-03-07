import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthClaims } from '../../security/auth-claims';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationResponseDto } from './dto/reservation-response.dto';
import { ReservationSupportListResponseDto } from './dto/reservation-support-response.dto';
export declare class ReservationService {
    private readonly legacySoapClient;
    constructor(legacySoapClient: LegacySoapClient);
    listReservations(mode: 'standard' | 'bulk', claims: AuthClaims): Promise<ReservationResponseDto[]>;
    createReservation(mode: 'standard' | 'bulk', dto: CreateReservationDto, claims: AuthClaims): Promise<{
        reservationNo: string;
        mode: 'standard' | 'bulk';
    }>;
    deleteReservation(mode: 'standard' | 'bulk', id: string, address: string, claims: AuthClaims): Promise<{
        ok: boolean;
    }>;
    getZipAreas(): Promise<ReservationSupportListResponseDto>;
    getAvailable(zip: string, claims: AuthClaims): Promise<ReservationSupportListResponseDto>;
    getAvailableBulk(zip: string, claims: AuthClaims): Promise<ReservationSupportListResponseDto>;
    getAreaCodes(claims: AuthClaims): Promise<ReservationSupportListResponseDto>;
    getArrived(claims: AuthClaims): Promise<ReservationSupportListResponseDto>;
}
