"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P1_CONTRACT_LIMITS = void 0;
exports.ensureMax = ensureMax;
exports.ensureOptionalMax = ensureOptionalMax;
exports.ensureMaxItems = ensureMaxItems;
exports.truncateMax = truncateMax;
exports.ensureIsoDatetime = ensureIsoDatetime;
const legacy_soap_error_1 = require("../../adapters/soap/legacy-soap.error");
exports.P1_CONTRACT_LIMITS = {
    token: 4096,
    refreshToken: 1024,
    userId: 64,
    contractNo: 64,
    userName: 128,
    role: 32,
    url: 2048,
    cookieCount: 20,
    cookieName: 64,
    cookieValue: 4096,
    cookieDomain: 255,
    cookiePath: 255,
    bulletinMessage: 2000,
    datetime: 40,
    subject: 64,
    deviceId: 64,
    platform: 16,
    fcmToken: 4096
};
function ensureMax(field, value, max) {
    if (value.length > max) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} exceeds max length ${max}.`);
    }
    return value;
}
function ensureOptionalMax(field, value, max) {
    if (value == null) {
        return null;
    }
    return ensureMax(field, value, max);
}
function ensureMaxItems(field, count, max) {
    if (count > max) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} exceeds max items ${max}.`);
    }
}
function truncateMax(value, max) {
    if (value.length <= max) {
        return value;
    }
    return value.slice(0, max);
}
function ensureIsoDatetime(field, value, max) {
    if (value == null) {
        return null;
    }
    const normalized = ensureMax(field, value, max);
    const parsed = Date.parse(normalized);
    if (Number.isNaN(parsed)) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} is not a valid ISO datetime.`);
    }
    return normalized;
}
//# sourceMappingURL=p1-contract-policy.js.map