import { Global, Module } from '@nestjs/common';
import { RedisTokenStoreService } from './redis-token-store.service';

@Global()
@Module({
  providers: [RedisTokenStoreService],
  exports: [RedisTokenStoreService]
})
export class SecurityModule {}
