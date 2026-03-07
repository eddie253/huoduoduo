import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { RegisterPushTokenDto } from './dto/register-push-token.dto';
import { UnregisterPushTokenDto } from './dto/unregister-push-token.dto';
export declare class NotificationService {
    private readonly legacySoapClient;
    constructor(legacySoapClient: LegacySoapClient);
    registerPushToken(contractNo: string, dto: RegisterPushTokenDto): Promise<{
        ok: boolean;
        registeredAt: string;
    }>;
    unregisterPushToken(contractNo: string, dto: UnregisterPushTokenDto): Promise<{
        ok: boolean;
        unregisteredAt: string;
    }>;
}
