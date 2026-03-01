import { Global, Module } from '@nestjs/common';
import { LegacySoapClient } from './legacy-soap.client';
import { SoapTransportService } from './soap-transport.service';

@Global()
@Module({
  providers: [SoapTransportService, LegacySoapClient],
  exports: [SoapTransportService, LegacySoapClient]
})
export class SoapModule {}
