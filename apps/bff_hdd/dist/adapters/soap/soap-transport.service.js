"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var SoapTransportService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SoapTransportService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const fast_xml_parser_1 = require("fast-xml-parser");
const number_env_1 = require("../../core/config/number-env");
const legacy_soap_error_1 = require("./legacy-soap.error");
let SoapTransportService = SoapTransportService_1 = class SoapTransportService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(SoapTransportService_1.name);
        this.parser = new fast_xml_parser_1.XMLParser({
            ignoreAttributes: false,
            trimValues: true
        });
    }
    async call(request) {
        const namespace = this.configService.get('SOAP_NAMESPACE', 'https://driver.huoduoduo.com.tw/');
        const baseUrl = this.configService.get('SOAP_BASE_URL', 'https://old.huoduoduo.com.tw');
        const path = this.configService.get('SOAP_PATH', '/Inquiry/didiservice.asmx');
        const timeoutMs = (0, number_env_1.readPositiveInt)(this.configService.get('SOAP_TIMEOUT_MS'), 15000, 'SOAP_TIMEOUT_MS', (message) => this.logger.warn(message));
        const endpoint = `${baseUrl.replace(/\/$/, '')}${path.startsWith('/') ? path : `/${path}`}`;
        const envelope = this.buildEnvelope(namespace, request.method, request.params ?? {});
        let responseText = '';
        let response;
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
        }
        catch (error) {
            if (error instanceof legacy_soap_error_1.LegacySoapError) {
                throw error;
            }
            if (error instanceof Error && error.name === 'AbortError') {
                throw new legacy_soap_error_1.LegacySoapError('LEGACY_TIMEOUT', 502, 'SOAP request timeout or network error.');
            }
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_TIMEOUT', 502, 'SOAP request timeout or network error.');
        }
        responseText = await response.text();
        if (!response.ok) {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `SOAP returned HTTP ${response.status}.`);
        }
        const parsed = this.tryParseXml(responseText);
        const methodResult = this.extractMethodResult(parsed, request.method);
        if (methodResult == null) {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'SOAP response missing result payload.');
        }
        return methodResult;
    }
    buildEnvelope(namespace, method, params) {
        const paramsXml = Object.entries(params)
            .map(([key, value]) => {
            const raw = value == null ? '' : String(value);
            return `<${key}>${this.escapeXml(raw)}</${key}>`;
        })
            .join('');
        return ('<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
            'xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +
            'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            `<${method} xmlns="${namespace}">${paramsXml}</${method}>` +
            '</soap:Body>' +
            '</soap:Envelope>');
    }
    tryParseXml(xml) {
        try {
            return this.parser.parse(xml);
        }
        catch {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'Failed to parse SOAP XML response.');
        }
    }
    extractMethodResult(parsed, method) {
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
    findValueByKey(node, targetKey) {
        if (!node || typeof node !== 'object') {
            return null;
        }
        for (const [key, value] of Object.entries(node)) {
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
    findValueBySuffix(node, suffix) {
        if (!node || typeof node !== 'object') {
            return null;
        }
        for (const [key, value] of Object.entries(node)) {
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
    escapeXml(input) {
        return input
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }
};
exports.SoapTransportService = SoapTransportService;
exports.SoapTransportService = SoapTransportService = SoapTransportService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], SoapTransportService);
//# sourceMappingURL=soap-transport.service.js.map