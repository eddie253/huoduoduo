"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LegacySoapExceptionFilter = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_error_1 = require("../adapters/soap/legacy-soap.error");
const p4_contract_policy_1 = require("../core/contracts/p4-contract-policy");
let LegacySoapExceptionFilter = class LegacySoapExceptionFilter {
    catch(exception, host) {
        const response = host.switchToHttp().getResponse();
        const normalized = this.normalizeException(exception);
        const payload = (0, p4_contract_policy_1.normalizeErrorResponseContract)(normalized.code, normalized.message);
        response.status(normalized.statusCode).json(payload);
    }
    normalizeException(exception) {
        if (exception instanceof legacy_soap_error_1.LegacySoapError) {
            return {
                statusCode: exception.statusCode,
                code: exception.code,
                message: exception.message
            };
        }
        if (exception instanceof common_1.HttpException) {
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
    extractCode(response) {
        if (!response || typeof response !== 'object') {
            return null;
        }
        const candidate = response.code;
        return typeof candidate === 'string' && candidate.trim() ? candidate : null;
    }
    extractMessage(response) {
        if (typeof response === 'string') {
            return response;
        }
        if (!response || typeof response !== 'object') {
            return null;
        }
        const candidate = response.message;
        if (typeof candidate === 'string') {
            return candidate;
        }
        if (Array.isArray(candidate)) {
            return candidate.map((item) => String(item)).join('; ');
        }
        return null;
    }
    statusToCode(statusCode) {
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
};
exports.LegacySoapExceptionFilter = LegacySoapExceptionFilter;
exports.LegacySoapExceptionFilter = LegacySoapExceptionFilter = __decorate([
    (0, common_1.Catch)()
], LegacySoapExceptionFilter);
//# sourceMappingURL=legacy-soap-exception.filter.js.map