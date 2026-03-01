import { Body, Controller, HttpCode, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { Throttle } from '@nestjs/throttler';
import { LoginRequestDto } from './dto/login-request.dto';
import { RefreshRequestDto } from './dto/refresh-request.dto';
import { AuthService } from './auth.service';
import { NoStoreResponse } from '../../security/no-store-response.decorator';
import { Public } from '../../security/public.decorator';

@NoStoreResponse()
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @HttpCode(200)
  @Post('login')
  login(@Body() dto: LoginRequestDto): Promise<Record<string, unknown>> {
    return this.authService.login(dto);
  }

  @Public()
  @HttpCode(200)
  @Post('refresh')
  refresh(@Body() dto: RefreshRequestDto): Promise<Record<string, unknown>> {
    return this.authService.refresh(dto.refreshToken);
  }

  @HttpCode(200)
  @Post('logout')
  async logout(
    @Body() body: { refreshToken?: string },
    @Req() request: Request
  ): Promise<{ revoked: boolean; subject: string }> {
    const user = (request as Request & { user?: { sub?: string } }).user;
    return {
      ...(await this.authService.logout(body?.refreshToken)),
      subject: user?.sub || 'unknown'
    };
  }
}
