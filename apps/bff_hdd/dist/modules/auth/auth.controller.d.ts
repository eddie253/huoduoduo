import type { Request } from 'express';
import { LoginRequestDto } from './dto/login-request.dto';
import { LogoutRequestDto } from './dto/logout-request.dto';
import { RefreshRequestDto } from './dto/refresh-request.dto';
import { AuthService } from './auth.service';
import { LoginResponseDto, LogoutResponseDto, RefreshResponseDto } from './dto/auth-response.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    login(dto: LoginRequestDto): Promise<LoginResponseDto>;
    refresh(dto: RefreshRequestDto): Promise<RefreshResponseDto>;
    logout(body: LogoutRequestDto, request: Request): Promise<LogoutResponseDto>;
}
