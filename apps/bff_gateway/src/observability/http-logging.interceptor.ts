import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';

@Injectable()
export class HttpLoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<any>();
    const response = context.switchToHttp().getResponse<any>();
    const started = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const durationMs = Date.now() - started;
          this.logger.log(
            `${request.method} ${request.url} ${response.statusCode} ${durationMs}ms`
          );
        }
      })
    );
  }
}
