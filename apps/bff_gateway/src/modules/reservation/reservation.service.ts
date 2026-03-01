import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthClaims } from '../../security/auth-claims';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationResponseDto } from './dto/reservation-response.dto';

@Injectable()
export class ReservationService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  listReservations(
    mode: 'standard' | 'bulk',
    claims: AuthClaims
  ): Promise<ReservationResponseDto[]> {
    return this.legacySoapClient.listReservations(mode, claims.contractNo);
  }

  createReservation(
    mode: 'standard' | 'bulk',
    dto: CreateReservationDto,
    claims: AuthClaims
  ): Promise<{ reservationNo: string; mode: 'standard' | 'bulk' }> {
    return this.legacySoapClient.createReservation(mode, {
      contractNo: claims.contractNo,
      address: dto.address,
      shipmentNos: dto.shipmentNos,
      fee: dto.fee
    });
  }

  async deleteReservation(
    mode: 'standard' | 'bulk',
    id: string,
    address: string,
    claims: AuthClaims
  ): Promise<{ ok: boolean }> {
    await this.legacySoapClient.deleteReservation(mode, id, address, claims.contractNo);
    return { ok: true };
  }
}
