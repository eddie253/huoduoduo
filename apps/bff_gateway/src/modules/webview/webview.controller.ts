import { Controller, Get, Req, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { AuthClaims } from '../../security/auth-claims';
import { WebviewBootstrapDto } from '../auth/auth.service';
import { WebviewService } from './webview.service';

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
}
