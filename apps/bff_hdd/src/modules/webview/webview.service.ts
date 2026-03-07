import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import {
  P1_CONTRACT_LIMITS,
  ensureIsoDatetime,
  truncateMax
} from '../../core/contracts/p1-contract-policy';
import { AuthService } from '../auth/auth.service';
import { WebviewBootstrapDto } from '../auth/dto/auth-response.dto';

export interface BulletinDto {
  message: string;
  hasAnnouncement: boolean;
  updatedAt: string | null;
}

@Injectable()
export class WebviewService {
  constructor(
    private readonly authService: AuthService,
    private readonly legacySoapClient: LegacySoapClient
  ) {}

  getBootstrap(account: string, identify: string): Promise<WebviewBootstrapDto> {
    return this.authService.getWebviewBootstrap(account, identify);
  }

  async getCurrentBulletin(): Promise<BulletinDto> {
    const bulletins = await this.legacySoapClient.getBulletins();
    const current = bulletins[0];
    if (!current) {
      return {
        message: '',
        hasAnnouncement: false,
        updatedAt: null
      };
    }

    return {
      message: truncateMax(current.title, P1_CONTRACT_LIMITS.bulletinMessage),
      hasAnnouncement: true,
      updatedAt: ensureIsoDatetime(
        'bootstrap.bulletin.updatedAt',
        current.date,
        P1_CONTRACT_LIMITS.datetime
      )
    };
  }
}
