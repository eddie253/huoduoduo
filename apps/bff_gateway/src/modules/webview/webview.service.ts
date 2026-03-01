import { Injectable } from '@nestjs/common';
import { AuthService, WebviewBootstrapDto } from '../auth/auth.service';

@Injectable()
export class WebviewService {
  constructor(private readonly authService: AuthService) {}

  getBootstrap(account: string, identify: string): Promise<WebviewBootstrapDto> {
    return this.authService.getWebviewBootstrap(account, identify);
  }
}
