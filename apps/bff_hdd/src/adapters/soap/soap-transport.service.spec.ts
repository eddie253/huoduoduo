import { ConfigService } from '@nestjs/config';
import { SoapTransportService } from './soap-transport.service';

describe('SoapTransportService', () => {
  const makeService = (overrides: Record<string, unknown> = {}) => {
    const configService = {
      get: jest.fn((key: string, fallback: unknown) => {
        const map: Record<string, unknown> = {
          SOAP_NAMESPACE: 'https://driver.huoduoduo.com.tw/',
          SOAP_BASE_URL: 'https://old.huoduoduo.com.tw',
          SOAP_PATH: '/Inquiry/didiservice.asmx',
          SOAP_TIMEOUT_MS: 5000
        };
        Object.assign(map, overrides);
        return map[key] ?? fallback;
      })
    } as unknown as ConfigService;
    return new SoapTransportService(configService);
  };

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('parses SOAP result payload', async () => {
    const xml = `<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetLoginResponse xmlns="https://driver.huoduoduo.com.tw/">
      <GetLoginResult>[{"契約編號":"D001"}]</GetLoginResult>
    </GetLoginResponse>
  </soap:Body>
</soap:Envelope>`;
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => xml
    } as Response);

    const service = makeService();
    const result = await service.call({ method: 'GetLogin', params: { Account: 'a' } });
    expect(result).toContain('D001');
  });

  it('throws LEGACY_BAD_RESPONSE when SOAP result missing', async () => {
    const xml = `<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetLoginResponse xmlns="https://driver.huoduoduo.com.tw/" />
  </soap:Body>
</soap:Envelope>`;
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => xml
    } as Response);

    const service = makeService();
    await expect(service.call({ method: 'GetLogin' })).rejects.toMatchObject({
      code: 'LEGACY_BAD_RESPONSE'
    });
  });

  it('throws LEGACY_TIMEOUT on network failure', async () => {
    jest.spyOn(global, 'fetch').mockRejectedValue(new Error('network down'));
    const service = makeService();
    await expect(service.call({ method: 'GetLogin' })).rejects.toMatchObject({
      code: 'LEGACY_TIMEOUT'
    });
  });

  it('parses string timeout configuration', async () => {
    const xml = `<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetLoginResponse xmlns="https://driver.huoduoduo.com.tw/">
      <GetLoginResult>[{"ContractNo":"D001"}]</GetLoginResult>
    </GetLoginResponse>
  </soap:Body>
</soap:Envelope>`;
    const timeoutSpy = jest.spyOn(AbortSignal, 'timeout');
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => xml
    } as Response);

    const service = makeService({ SOAP_TIMEOUT_MS: '15000' });
    await service.call({ method: 'GetLogin' });
    expect(timeoutSpy).toHaveBeenCalledWith(15000);
  });

  it('falls back to default timeout when configuration is invalid', async () => {
    const xml = `<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetLoginResponse xmlns="https://driver.huoduoduo.com.tw/">
      <GetLoginResult>[{"ContractNo":"D001"}]</GetLoginResult>
    </GetLoginResponse>
  </soap:Body>
</soap:Envelope>`;
    const timeoutSpy = jest.spyOn(AbortSignal, 'timeout');
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => xml
    } as Response);

    const service = makeService({ SOAP_TIMEOUT_MS: 'abc' });
    await service.call({ method: 'GetLogin' });
    expect(timeoutSpy).toHaveBeenCalledWith(15000);
  });
});
