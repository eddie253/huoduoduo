import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { AuthService } from '../auth/auth.service';
import { WebviewService } from './webview.service';

describe('WebviewService contract enforcement', () => {
  it('truncates oversized bulletin message', async () => {
    const authService = {} as AuthService;
    const legacySoapClient = {
      getBulletins: jest.fn(async () => [
        {
          uid: '1',
          title: 'B'.repeat(2400),
          date: '2026-03-02T00:00:00Z'
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new WebviewService(authService, legacySoapClient);
    const result = await service.getCurrentBulletin();

    expect(result.hasAnnouncement).toBe(true);
    expect(result.message.length).toBe(2000);
    expect(result.updatedAt).toBe('2026-03-02T00:00:00Z');
  });

  it('rejects invalid bulletin datetime', async () => {
    const authService = {} as AuthService;
    const legacySoapClient = {
      getBulletins: jest.fn(async () => [
        {
          uid: '1',
          title: 'valid-title',
          date: 'not-a-date'
        }
      ])
    } as unknown as LegacySoapClient;

    const service = new WebviewService(authService, legacySoapClient);
    await expect(service.getCurrentBulletin()).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });
});
