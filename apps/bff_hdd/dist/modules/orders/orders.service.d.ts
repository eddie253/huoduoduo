import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { IdempotencyGuardService } from '../../shared/idempotency/idempotency-guard.service';
import { AuthClaims } from '../../security/auth-claims';
export declare class OrdersService {
    private readonly legacySoapClient;
    private readonly idempotencyGuard;
    constructor(legacySoapClient: LegacySoapClient, idempotencyGuard: IdempotencyGuardService);
    acceptOrder(trackingNo: string, claims: AuthClaims, idempotencyKey: string): Promise<{
        ok: boolean;
    }>;
}
