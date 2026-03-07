import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { NO_STORE_RESPONSE_METADATA_KEY } from './no-store-response.decorator';

@Injectable()
export class NoStoreResponseInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const enabled = this.reflector.getAllAndOverride<boolean>(
      NO_STORE_RESPONSE_METADATA_KEY,
      [context.getHandler(), context.getClass()]
    );
    if (enabled) {
      const response = context.switchToHttp().getResponse<{
        setHeader: (name: string, value: string) => void;
      }>();
      response.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
      response.setHeader('Pragma', 'no-cache');
      response.setHeader('Expires', '0');
    }
    return next.handle();
  }
}
