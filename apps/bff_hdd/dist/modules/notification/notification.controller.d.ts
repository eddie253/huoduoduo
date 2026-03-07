import type { Request } from 'express';
import { RegisterPushTokenDto } from './dto/register-push-token.dto';
import { UnregisterPushTokenDto } from './dto/unregister-push-token.dto';
import { NotificationService } from './notification.service';
export declare class NotificationController {
    private readonly notificationService;
    constructor(notificationService: NotificationService);
    registerPushToken(request: Request, dto: RegisterPushTokenDto): Promise<{
        ok: boolean;
        registeredAt: string;
    }>;
    unregisterPushToken(request: Request, dto: UnregisterPushTokenDto): Promise<{
        ok: boolean;
        unregisteredAt: string;
    }>;
}
