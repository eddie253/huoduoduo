import { ArgumentsHost, ExceptionFilter } from '@nestjs/common';
export declare class LegacySoapExceptionFilter implements ExceptionFilter {
    catch(exception: unknown, host: ArgumentsHost): void;
    private normalizeException;
    private extractCode;
    private extractMessage;
    private statusToCode;
}
