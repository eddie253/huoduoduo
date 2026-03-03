import { BadRequestException } from '@nestjs/common';
import { LegacySoapError } from '../adapters/soap/legacy-soap.error';
import { LegacySoapExceptionFilter } from './legacy-soap-exception.filter';

describe('LegacySoapExceptionFilter', () => {
  const makeHost = () => {
    const json = jest.fn();
    const status = jest.fn(() => ({ json }));
    return {
      status,
      json,
      host: {
        switchToHttp: () => ({
          getResponse: () => ({
            status
          })
        })
      }
    };
  };

  it('preserves legacy code and truncates over-length message', () => {
    const filter = new LegacySoapExceptionFilter();
    const { host, status, json } = makeHost();
    filter.catch(
      new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'x'.repeat(1300)),
      host as never
    );

    expect(status).toHaveBeenCalledWith(502);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'LEGACY_BAD_RESPONSE'
      })
    );
    const payload = json.mock.calls[0][0] as { message: string };
    expect(payload.message.length).toBeLessThanOrEqual(1024);
  });

  it('maps HttpException to code/message contract shape', () => {
    const filter = new LegacySoapExceptionFilter();
    const { host, status, json } = makeHost();
    filter.catch(new BadRequestException(['field should not be empty']), host as never);

    expect(status).toHaveBeenCalledWith(400);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'BAD_REQUEST'
      })
    );
  });
});
