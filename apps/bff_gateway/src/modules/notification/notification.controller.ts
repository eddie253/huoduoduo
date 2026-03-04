import { Body, Controller, HttpCode, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { RegisterPushTokenDto } from './dto/register-push-token.dto';
import { UnregisterPushTokenDto } from './dto/unregister-push-token.dto';
import { NotificationService } from './notification.service';
import { NoStoreResponse } from '../../security/no-store-response.decorator';

@NoStoreResponse()
@Controller('push')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post('register')
  @HttpCode(200)
  async registerPushToken(
    @Req() request: Request,
    @Body() dto: RegisterPushTokenDto
  ): Promise<{ ok: boolean; registeredAt: string }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.notificationService.registerPushToken(claims.contractNo, dto);
  }

  @Post('unregister')
  @HttpCode(200)
  async unregisterPushToken(
    @Req() request: Request,
    @Body() dto: UnregisterPushTokenDto
  ): Promise<{ ok: boolean; unregisteredAt: string }> {
    const claims = (request as Request & { user: AuthClaims }).user;
    return this.notificationService.unregisterPushToken(claims.contractNo, dto);
  }
}
