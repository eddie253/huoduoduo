jest.mock('@nestjs/core', () => ({ NestFactory: { create: jest.fn() } }));
jest.mock('helmet');
jest.mock('./app.module', () => ({ AppModule: class AppModule {} }));
jest.mock('./security/legacy-soap-exception.filter', () => ({
  LegacySoapExceptionFilter: class LegacySoapExceptionFilter {}
}));

import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import { bootstrap } from './main';

describe('bootstrap() smoke test', () => {
  let mockApp: { use: jest.Mock; setGlobalPrefix: jest.Mock; useGlobalPipes: jest.Mock; useGlobalFilters: jest.Mock; listen: jest.Mock };

  beforeEach(() => {
    mockApp = {
      use: jest.fn(),
      setGlobalPrefix: jest.fn(),
      useGlobalPipes: jest.fn(),
      useGlobalFilters: jest.fn(),
      listen: jest.fn().mockResolvedValue(undefined)
    };
    (NestFactory.create as jest.Mock).mockResolvedValue(mockApp);
    (helmet as unknown as jest.Mock).mockReturnValue(jest.fn());
  });

  afterEach(() => jest.clearAllMocks());

  it('creates NestJS app with cors enabled', async () => {
    await bootstrap();
    expect(NestFactory.create).toHaveBeenCalledWith(expect.anything(), { cors: true });
  });

  it('registers helmet with correct csp flags', async () => {
    await bootstrap();
    expect(helmet).toHaveBeenCalledWith({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false });
  });

  it('sets global prefix to v1', async () => {
    await bootstrap();
    expect(mockApp.setGlobalPrefix).toHaveBeenCalledWith('v1');
  });

  it('registers ValidationPipe', async () => {
    await bootstrap();
    expect(mockApp.useGlobalPipes).toHaveBeenCalledTimes(1);
  });

  it('registers LegacySoapExceptionFilter', async () => {
    await bootstrap();
    expect(mockApp.useGlobalFilters).toHaveBeenCalledTimes(1);
  });

  it('listens on PORT env var when set', async () => {
    process.env.PORT = '8080';
    await bootstrap();
    expect(mockApp.listen).toHaveBeenCalledWith(8080);
    delete process.env.PORT;
  });

  it('defaults to port 3000 when PORT is unset', async () => {
    delete process.env.PORT;
    await bootstrap();
    expect(mockApp.listen).toHaveBeenCalledWith(3000);
  });
});
