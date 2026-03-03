import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { NotificationService } from './notification.service';

describe('NotificationService contract enforcement', () => {
  it('returns ISO registeredAt with max length <= 40', async () => {
    const legacySoapClient = {
      updateRegId: jest.fn(async () => undefined)
    } as unknown as LegacySoapClient;

    const service = new NotificationService(legacySoapClient);
    const result = await service.registerPushToken('D001', {
      deviceId: 'device-1',
      platform: 'android',
      fcmToken: 'fcm-token-1',
      appVersion: 1
    });

    expect(result.ok).toBe(true);
    expect(typeof result.registeredAt).toBe('string');
    expect(result.registeredAt.length).toBeLessThanOrEqual(40);
    expect(Number.isNaN(Date.parse(result.registeredAt))).toBe(false);
  });
});
