import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthService, WebviewBootstrapDto } from '../auth/auth.service';

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
      message: current.title,
      hasAnnouncement: true,
      updatedAt: current.date
    };
  }
}
