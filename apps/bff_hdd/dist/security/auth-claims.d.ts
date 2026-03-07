export interface AuthClaims {
    sub: string;
    account: string;
    role: string;
    contractNo: string;
    identify: string;
    platform: 'android' | 'ios';
    deviceId: string;
    jti: string;
    iat?: number;
    exp?: number;
}
