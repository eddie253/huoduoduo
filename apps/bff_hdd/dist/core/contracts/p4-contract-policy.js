"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P4_CONTRACT_LIMITS = void 0;
exports.enforceHealthResponseContract = enforceHealthResponseContract;
exports.normalizeErrorResponseContract = normalizeErrorResponseContract;
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P4_CONTRACT_LIMITS = {
    errorCode: 64,
    errorMessage: 1024,
    healthStatus: 32,
    healthService: 64,
    datetime: 40
};
function enforceHealthResponseContract(payload, fieldPrefix = 'health.response') {
    const status = (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.status`, payload.status, exports.P4_CONTRACT_LIMITS.healthStatus);
    const service = (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.service`, payload.service, exports.P4_CONTRACT_LIMITS.healthService);
    const timestamp = (0, p1_contract_policy_1.ensureIsoDatetime)(`${fieldPrefix}.timestamp`, payload.timestamp, exports.P4_CONTRACT_LIMITS.datetime) || new Date(0).toISOString();
    return {
        status,
        service,
        timestamp
    };
}
function normalizeErrorResponseContract(code, message) {
    const safeCode = normalizeCode(code);
    const safeMessage = normalizeMessage(message);
    return {
        code: safeCode,
        message: safeMessage
    };
}
function normalizeCode(code) {
    const normalized = String(code ?? '').trim();
    if (!normalized) {
        return 'INTERNAL_SERVER_ERROR';
    }
    if (normalized.length > exports.P4_CONTRACT_LIMITS.errorCode) {
        return 'INTERNAL_SERVER_ERROR';
    }
    return normalized;
}
function normalizeMessage(message) {
    const normalized = String(message ?? '').trim();
    if (!normalized) {
        return 'Internal server error.';
    }
    return (0, p1_contract_policy_1.truncateMax)(normalized, exports.P4_CONTRACT_LIMITS.errorMessage);
}
//# sourceMappingURL=p4-contract-policy.js.map