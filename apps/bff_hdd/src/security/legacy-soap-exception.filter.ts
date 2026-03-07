import {
  ArgumentsHost,
  HttpException,
  Catch,
  ExceptionFilter
} from '@nestjs/common';
import { Response } from 'express';
import { LegacySoapError } from '../adapters/soap/legacy-soap.error';
import { normalizeErrorResponseContract } from '../core/contracts/p4-contract-policy';

@Catch()
export class LegacySoapExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const normalized = this.normalizeException(exception);
    const payload = normalizeErrorResponseContract(normalized.code, normalized.message);
    response.status(normalized.statusCode).json(payload);
  }

  private normalizeException(exception: unknown): {
    statusCode: number;
    code: string;
    message: string;
  } {
    if (exception instanceof LegacySoapError) {
      return {
        statusCode: exception.statusCode,
        code: exception.code,
        message: exception.message
      };
    }

    if (exception instanceof HttpException) {
      const statusCode = exception.getStatus();
      const response = exception.getResponse();
      const code = this.extractCode(response) || this.statusToCode(statusCode);
      const message = this.extractMessage(response) || exception.message || 'Request failed.';
      return {
        statusCode,
        code,
        message
      };
    }

    if (exception instanceof Error) {
      return {
        statusCode: 500,
        code: 'INTERNAL_SERVER_ERROR',
        message: exception.message || 'Internal server error.'
      };
    }

    return {
      statusCode: 500,
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error.'
    };
  }

  private extractCode(response: unknown): string | null {
    if (!response || typeof response !== 'object') {
      return null;
    }
    const candidate = (response as Record<string, unknown>).code;
    return typeof candidate === 'string' && candidate.trim() ? candidate : null;
  }

  private extractMessage(response: unknown): string | null {
    if (typeof response === 'string') {
      return response;
    }
    if (!response || typeof response !== 'object') {
      return null;
    }

    const candidate = (response as Record<string, unknown>).message;
    if (typeof candidate === 'string') {
      return candidate;
    }
    if (Array.isArray(candidate)) {
      return candidate.map((item) => String(item)).join('; ');
    }
    return null;
  }

  private statusToCode(statusCode: number): string {
    switch (statusCode) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 429:
        return 'TOO_MANY_REQUESTS';
      default:
        return 'INTERNAL_SERVER_ERROR';
    }
  }
}
