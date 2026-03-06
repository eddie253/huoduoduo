import { Global, Module } from '@nestjs/common';
import { IdempotencyGuardService } from './idempotency-guard.service';

@Global()
@Module({
  providers: [IdempotencyGuardService],
  exports: [IdempotencyGuardService]
})
export class IdempotencyModule {}
