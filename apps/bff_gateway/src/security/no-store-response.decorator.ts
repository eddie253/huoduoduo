import { SetMetadata } from '@nestjs/common';

export const NO_STORE_RESPONSE_METADATA_KEY = 'security:no-store-response';

export const NoStoreResponse = (): MethodDecorator & ClassDecorator =>
  SetMetadata(NO_STORE_RESPONSE_METADATA_KEY, true);
