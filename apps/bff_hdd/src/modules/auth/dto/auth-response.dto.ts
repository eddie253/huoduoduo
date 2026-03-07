import { WebCookieModel } from '../../../adapters/soap/legacy-soap.client';

export interface UserProfileDto {
  id: string;
  contractNo: string;
  name: string;
  role: string;
}

export interface WebviewBootstrapDto {
  baseUrl: string;
  registerUrl: string;
  resetPasswordUrl: string;
  cookies: WebCookieModel[];
}

export interface LoginResponseDto {
  accessToken: string;
  refreshToken: string;
  user: UserProfileDto;
  webviewBootstrap: WebviewBootstrapDto;
}

export interface RefreshResponseDto {
  accessToken: string;
  refreshToken: string;
}

export interface LogoutResponseDto {
  revoked: boolean;
  subject: string;
}
