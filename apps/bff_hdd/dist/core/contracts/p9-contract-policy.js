"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P9_CONTRACT_LIMITS = void 0;
exports.enforceSystemVersionResponseContract = enforceSystemVersionResponseContract;
exports.parseLegacyVersionCode = parseLegacyVersionCode;
const legacy_soap_error_1 = require("../../adapters/soap/legacy-soap.error");
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P9_CONTRACT_LIMITS = {
    regId: 4096,
    datetime: 40,
    versionName: 64,
    versionRaw: 64
};
function enforceSystemVersionResponseContract(payload, fieldPrefix = 'system.version.response') {
    return {
        name: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.name`, payload.name, exports.P9_CONTRACT_LIMITS.versionName),
        versionCode: ensureVersionCode(`${fieldPrefix}.versionCode`, payload.versionCode)
    };
}
function parseLegacyVersionCode(raw, fieldPrefix = 'system.version.response') {
    const normalizedRaw = (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.raw`, String(raw).trim(), exports.P9_CONTRACT_LIMITS.versionRaw);
    if (!normalizedRaw) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw is empty.`);
    }
    const direct = normalizeVersionToken(normalizedRaw);
    if (direct != null) {
        return direct;
    }
    try {
        const parsed = JSON.parse(normalizedRaw);
        const candidate = extractVersionCandidate(parsed);
        if (candidate == null) {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw has no version token.`);
        }
        const fromJson = normalizeVersionToken(candidate);
        if (fromJson == null) {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw is not a valid version code.`);
        }
        return fromJson;
    }
    catch (error) {
        if (error instanceof legacy_soap_error_1.LegacySoapError) {
            throw error;
        }
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${fieldPrefix}.raw is not a valid numeric version payload.`);
    }
}
function ensureVersionCode(field, value) {
    if (!Number.isInteger(value) || value < 0) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be a non-negative integer.`);
    }
    return value;
}
function normalizeVersionToken(input) {
    const normalized = input.trim().replace(/^"+|"+$/g, '');
    if (!/^\d+$/.test(normalized)) {
        return null;
    }
    const numeric = Number(normalized);
    if (!Number.isSafeInteger(numeric) || numeric < 0) {
        return null;
    }
    return numeric;
}
function extractVersionCandidate(parsed) {
    if (typeof parsed === 'string') {
        return parsed;
    }
    if (typeof parsed === 'number' && Number.isFinite(parsed)) {
        return String(parsed);
    }
    if (Array.isArray(parsed) && parsed.length > 0) {
        return extractVersionCandidate(parsed[0]);
    }
    if (parsed && typeof parsed === 'object') {
        const record = parsed;
        const keys = ['Version', 'version', 'VersionCode', 'versionCode', 'Code', 'code', 'Value', 'value'];
        for (const key of keys) {
            const value = record[key];
            if (typeof value === 'string' || typeof value === 'number') {
                return String(value);
            }
        }
        const firstScalar = Object.values(record).find((value) => typeof value === 'string' || typeof value === 'number');
        if (firstScalar != null) {
            return String(firstScalar);
        }
    }
    return null;
}
//# sourceMappingURL=p9-contract-policy.js.map