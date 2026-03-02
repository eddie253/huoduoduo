import { Controller, Get, Req, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { NoStoreResponse } from '../../security/no-store-response.decorator';
import { WebviewBootstrapDto } from '../auth/auth.service';
import { BulletinDto, WebviewService } from './webview.service';

@NoStoreResponse()
@Controller('bootstrap')
export class WebviewController {
  constructor(private readonly webviewService: WebviewService) {}

  @Get('webview')
  getWebviewBootstrap(@Req() request: Request): Promise<WebviewBootstrapDto> {
    const claims = (request as Request & { user?: AuthClaims }).user;
    if (!claims) {
      throw new UnauthorizedException('Missing auth claims.');
    }
    return this.webviewService.getBootstrap(claims.account, claims.identify);
  }

  @Get('bulletin')
  getCurrentBulletin(@Req() request: Request): Promise<BulletinDto> {
    const claims = (request as Request & { user?: AuthClaims }).user;
    if (!claims) {
      throw new UnauthorizedException('Missing auth claims.');
    }
    return this.webviewService.getCurrentBulletin();
  }
}
