import { LegacySoapError } from '../../adapters/soap/legacy-soap.error';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { SystemService } from './system.service';

describe('SystemService contract enforcement', () => {
  it('parses legacy numeric version payload', async () => {
    const legacySoapClient = {
      getVersion: jest.fn(async () => '123')
    } as unknown as LegacySoapClient;

    const service = new SystemService(legacySoapClient);
    const result = await service.getVersion('DirverAPP');

    expect(result.name).toBe('DirverAPP');
    expect(result.versionCode).toBe(123);
  });

  it('rejects invalid version payload', async () => {
    const legacySoapClient = {
      getVersion: jest.fn(async () => 'not-a-version')
    } as unknown as LegacySoapClient;

    const service = new SystemService(legacySoapClient);
    await expect(service.getVersion('DirverAPP')).rejects.toMatchObject<Partial<LegacySoapError>>({
      code: 'LEGACY_BAD_RESPONSE',
      statusCode: 502
    });
  });
});
