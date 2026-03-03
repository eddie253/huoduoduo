import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { P1_CONTRACT_LIMITS, ensureMax } from '../../core/contracts/p1-contract-policy';
import {
  P3_CONTRACT_LIMITS,
  enforceReservationCreateContract,
  enforceReservationListContract
} from '../../core/contracts/p3-contract-policy';
import { AuthClaims } from '../../security/auth-claims';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { ReservationResponseDto } from './dto/reservation-response.dto';

@Injectable()
export class ReservationService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  async listReservations(
    mode: 'standard' | 'bulk',
    claims: AuthClaims
  ): Promise<ReservationResponseDto[]> {
    const normalizedContractNo = ensureMax(
      'reservations.list.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const reservations = await this.legacySoapClient.listReservations(mode, normalizedContractNo);
    return enforceReservationListContract(reservations);
  }

  async createReservation(
    mode: 'standard' | 'bulk',
    dto: CreateReservationDto,
    claims: AuthClaims
  ): Promise<{ reservationNo: string; mode: 'standard' | 'bulk' }> {
    const normalizedContractNo = ensureMax(
      'reservations.create.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );
    const normalizedAddress = ensureMax(
      'reservations.create.request.address',
      dto.address,
      P3_CONTRACT_LIMITS.address
    );
    const normalizedShipmentNos = dto.shipmentNos.map((shipmentNo, index) =>
      ensureMax(
        `reservations.create.request.shipmentNos[${index}]`,
        shipmentNo,
        P3_CONTRACT_LIMITS.shipmentNo
      )
    );

    const created = await this.legacySoapClient.createReservation(mode, {
      contractNo: normalizedContractNo,
      address: normalizedAddress,
      shipmentNos: normalizedShipmentNos,
      fee: dto.fee
    });
    return enforceReservationCreateContract(created);
  }

  async deleteReservation(
    mode: 'standard' | 'bulk',
    id: string,
    address: string,
    claims: AuthClaims
  ): Promise<{ ok: boolean }> {
    const normalizedId = ensureMax('reservations.delete.request.id', id, P3_CONTRACT_LIMITS.reservationNo);
    const normalizedAddress = ensureMax(
      'reservations.delete.request.address',
      address,
      P3_CONTRACT_LIMITS.address
    );
    const normalizedContractNo = ensureMax(
      'reservations.delete.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );

    await this.legacySoapClient.deleteReservation(mode, normalizedId, normalizedAddress, normalizedContractNo);
    return { ok: true };
  }
}
