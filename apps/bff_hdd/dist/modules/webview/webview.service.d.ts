import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { AuthService } from '../auth/auth.service';
import { WebviewBootstrapDto } from '../auth/dto/auth-response.dto';
export interface BulletinDto {
    message: string;
    hasAnnouncement: boolean;
    updatedAt: string | null;
}
export declare class WebviewService {
    private readonly authService;
    private readonly legacySoapClient;
    constructor(authService: AuthService, legacySoapClient: LegacySoapClient);
    getBootstrap(account: string, identify: string): Promise<WebviewBootstrapDto>;
    getCurrentBulletin(): Promise<BulletinDto>;
}
