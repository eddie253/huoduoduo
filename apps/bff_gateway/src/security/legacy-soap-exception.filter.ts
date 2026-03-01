import {
  ArgumentsHost,
  Catch,
  ExceptionFilter
} from '@nestjs/common';
import { Response } from 'express';
import { LegacySoapError } from '../adapters/soap/legacy-soap.error';

@Catch(LegacySoapError)
export class LegacySoapExceptionFilter implements ExceptionFilter {
  catch(exception: LegacySoapError, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.status(exception.statusCode).json({
      code: exception.code,
      message: exception.message
    });
  }
}
