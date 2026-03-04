import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import {
  P1_CONTRACT_LIMITS,
  ensureIsoDatetime
} from '../../core/contracts/p1-contract-policy';
import { P9_CONTRACT_LIMITS } from '../../core/contracts/p9-contract-policy';
import { RegisterPushTokenDto } from './dto/register-push-token.dto';
import { UnregisterPushTokenDto } from './dto/unregister-push-token.dto';

@Injectable()
export class NotificationService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  async registerPushToken(
    contractNo: string,
    dto: RegisterPushTokenDto
  ): Promise<{ ok: boolean; registeredAt: string }> {
    const kind = dto.platform === 'ios' ? 'ios' : 'Android';
    await this.legacySoapClient.updateRegId(
      contractNo,
      dto.fcmToken,
      kind,
      dto.appVersion ?? 0
    );
    const registeredAt = ensureIsoDatetime(
      'push.register.registeredAt',
      new Date().toISOString(),
      P1_CONTRACT_LIMITS.datetime
    );
    return {
      ok: true,
      registeredAt: registeredAt!
    };
  }

  async unregisterPushToken(
    contractNo: string,
    dto: UnregisterPushTokenDto
  ): Promise<{ ok: boolean; unregisteredAt: string }> {
    await this.legacySoapClient.deleteRegId(contractNo, dto.fcmToken);
    const unregisteredAt = ensureIsoDatetime(
      'push.unregister.unregisteredAt',
      new Date().toISOString(),
      P9_CONTRACT_LIMITS.datetime
    );
    return {
      ok: true,
      unregisteredAt: unregisteredAt!
    };
  }
}
