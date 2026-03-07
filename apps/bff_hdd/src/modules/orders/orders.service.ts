import { Injectable, ConflictException, BadRequestException } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { IdempotencyGuardService } from '../../shared/idempotency/idempotency-guard.service';
import { AuthClaims } from '../../security/auth-claims';
import {
  P1_CONTRACT_LIMITS,
  ensureMax
} from '../../core/contracts/p1-contract-policy';
import {
  P2_CONTRACT_LIMITS
} from '../../core/contracts/p2-contract-policy';

const IDEMPOTENCY_TTL_SECONDS = 86400;

@Injectable()
export class OrdersService {
  constructor(
    private readonly legacySoapClient: LegacySoapClient,
    private readonly idempotencyGuard: IdempotencyGuardService
  ) {}

  async acceptOrder(
    trackingNo: string,
    claims: AuthClaims,
    idempotencyKey: string
  ): Promise<{ ok: boolean }> {
    if (!idempotencyKey) {
      throw new BadRequestException('X-Idempotency-Key header is required');
    }

    const normalizedTrackingNo = ensureMax(
      'orders.accept.request.trackingNo',
      trackingNo,
      P2_CONTRACT_LIMITS.trackingNo
    );
    const normalizedContractNo = ensureMax(
      'orders.accept.request.contractNo',
      claims.contractNo,
      P1_CONTRACT_LIMITS.contractNo
    );

    const isUnique = await this.idempotencyGuard.ensureUnique(
      `order_accept:${normalizedTrackingNo}`,
      idempotencyKey,
      IDEMPOTENCY_TTL_SECONDS
    );

    if (!isUnique) {
      throw new ConflictException({
        code: 'ORDER_ALREADY_TAKEN',
        message: 'This order has already been accepted'
      });
    }

    try {
      await this.legacySoapClient.acceptOrder(normalizedContractNo, normalizedTrackingNo);
      return { ok: true };
    } catch (error) {
      if (error instanceof LegacySoapError) {
        const errorMessage = error.message.toLowerCase();
        if (errorMessage.includes('already') || errorMessage.includes('已被')) {
          throw new ConflictException({
            code: 'ORDER_ALREADY_TAKEN',
            message: 'This order has already been accepted by another driver'
          });
        }
      }
      throw error;
    }
  }
}
