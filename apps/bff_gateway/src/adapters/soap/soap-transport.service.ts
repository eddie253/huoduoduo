import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { XMLParser } from 'fast-xml-parser';
import { readPositiveInt } from '../../core/config/number-env';
import { LegacySoapError } from './legacy-soap.error';

interface SoapCallRequest {
  method: string;
  params?: Record<string, string | number | boolean | null | undefined>;
}

@Injectable()
export class SoapTransportService {
  private readonly logger = new Logger(SoapTransportService.name);
  private readonly parser = new XMLParser({
    ignoreAttributes: false,
    trimValues: true
  });

  constructor(private readonly configService: ConfigService) {}

  async call(request: SoapCallRequest): Promise<string> {
    const namespace = this.configService.get<string>('SOAP_NAMESPACE', 'https://driver.huoduoduo.com.tw/');
    const baseUrl = this.configService.get<string>('SOAP_BASE_URL', 'https://old.huoduoduo.com.tw');
    const path = this.configService.get<string>('SOAP_PATH', '/Inquiry/didiservice.asmx');
    const timeoutMs = readPositiveInt(
      this.configService.get('SOAP_TIMEOUT_MS'),
      15000,
      'SOAP_TIMEOUT_MS',
      (message) => this.logger.warn(message)
    );
    const endpoint = `${baseUrl.replace(/\/$/, '')}${path.startsWith('/') ? path : `/${path}`}`;

    const envelope = this.buildEnvelope(namespace, request.method, request.params ?? {});
    let responseText = '';

    let response: Response;
    try {
      response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          SOAPAction: `${namespace}${request.method}`
        },
        body: envelope,
        signal: AbortSignal.timeout(timeoutMs)
      });

    } catch (error) {
      if (error instanceof LegacySoapError) {
        throw error;
      }
      if (error instanceof Error && error.name === 'AbortError') {
        throw new LegacySoapError('LEGACY_TIMEOUT', 502, 'SOAP request timeout or network error.');
      }
      throw new LegacySoapError('LEGACY_TIMEOUT', 502, 'SOAP request timeout or network error.');
    }

    responseText = await response.text();
    if (!response.ok) {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, `SOAP returned HTTP ${response.status}.`);
    }

    const parsed = this.tryParseXml(responseText);
    const methodResult = this.extractMethodResult(parsed, request.method);
    if (methodResult == null) {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'SOAP response missing result payload.');
    }
    return methodResult;
  }

  private buildEnvelope(
    namespace: string,
    method: string,
    params: Record<string, string | number | boolean | null | undefined>
  ): string {
    const paramsXml = Object.entries(params)
      .map(([key, value]) => {
        const raw = value == null ? '' : String(value);
        return `<${key}>${this.escapeXml(raw)}</${key}>`;
      })
      .join('');

    return (
      '<?xml version="1.0" encoding="utf-8"?>' +
      '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
      'xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +
      'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
      '<soap:Body>' +
      `<${method} xmlns="${namespace}">${paramsXml}</${method}>` +
      '</soap:Body>' +
      '</soap:Envelope>'
    );
  }

  private tryParseXml(xml: string): Record<string, unknown> {
    try {
      return this.parser.parse(xml) as Record<string, unknown>;
    } catch {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'Failed to parse SOAP XML response.');
    }
  }

  private extractMethodResult(parsed: Record<string, unknown>, method: string): string | null {
    const methodResultKey = `${method}Result`;
    const direct = this.findValueByKey(parsed, methodResultKey);
    if (typeof direct === 'string') {
      return direct;
    }
    if (typeof direct === 'number' || typeof direct === 'boolean') {
      return String(direct);
    }

    const fallback = this.findValueBySuffix(parsed, 'Result');
    if (typeof fallback === 'string') {
      return fallback;
    }
    if (typeof fallback === 'number' || typeof fallback === 'boolean') {
      return String(fallback);
    }
    return null;
  }

  private findValueByKey(node: unknown, targetKey: string): unknown {
    if (!node || typeof node !== 'object') {
      return null;
    }
    for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
      if (key === targetKey || key.endsWith(`:${targetKey}`)) {
        return value;
      }
      const nested = this.findValueByKey(value, targetKey);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  private findValueBySuffix(node: unknown, suffix: string): unknown {
    if (!node || typeof node !== 'object') {
      return null;
    }
    for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
      if (key === suffix || key.endsWith(`:${suffix}`) || key.endsWith(suffix)) {
        return value;
      }
      const nested = this.findValueBySuffix(value, suffix);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  private escapeXml(input: string): string {
    return input
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}
