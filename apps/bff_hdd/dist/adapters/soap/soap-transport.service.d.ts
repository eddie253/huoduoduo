import { ConfigService } from '@nestjs/config';
interface SoapCallRequest {
    method: string;
    params?: Record<string, string | number | boolean | null | undefined>;
}
export declare class SoapTransportService {
    private readonly configService;
    private readonly logger;
    private readonly parser;
    constructor(configService: ConfigService);
    call(request: SoapCallRequest): Promise<string>;
    private buildEnvelope;
    private tryParseXml;
    private extractMethodResult;
    private findValueByKey;
    private findValueBySuffix;
    private escapeXml;
}
export {};
