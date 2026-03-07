import { Body, Controller, HttpCode, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { Throttle } from '@nestjs/throttler';
import { P1_CONTRACT_LIMITS, ensureMax } from '../../core/contracts/p1-contract-policy';
import { LoginRequestDto } from './dto/login-request.dto';
import { LogoutRequestDto } from './dto/logout-request.dto';
import { RefreshRequestDto } from './dto/refresh-request.dto';
import { AuthService } from './auth.service';
import { LoginResponseDto, LogoutResponseDto, RefreshResponseDto } from './dto/auth-response.dto';
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
  login(@Body() dto: LoginRequestDto): Promise<LoginResponseDto> {
    return this.authService.login(dto);
  }

  @Public()
  @HttpCode(200)
  @Post('refresh')
  refresh(@Body() dto: RefreshRequestDto): Promise<RefreshResponseDto> {
    return this.authService.refresh(dto.refreshToken);
  }

  @HttpCode(200)
  @Post('logout')
  async logout(
    @Body() body: LogoutRequestDto,
    @Req() request: Request
  ): Promise<LogoutResponseDto> {
    const user = (request as Request & { user?: { sub?: string } }).user;
    const subject = ensureMax('auth.logout.subject', user?.sub || 'unknown', P1_CONTRACT_LIMITS.subject);
    return {
      ...(await this.authService.logout(body?.refreshToken)),
      subject
    };
  }
}
