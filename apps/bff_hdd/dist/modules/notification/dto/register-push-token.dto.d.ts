export declare class RegisterPushTokenDto {
    deviceId: string;
    platform: 'android' | 'ios';
    fcmToken: string;
    appVersion?: number;
}
