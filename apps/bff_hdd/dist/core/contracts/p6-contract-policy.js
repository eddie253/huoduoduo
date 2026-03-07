"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P6_CONTRACT_LIMITS = void 0;
exports.enforceCurrencyListContract = enforceCurrencyListContract;
const legacy_soap_error_1 = require("../../adapters/soap/legacy-soap.error");
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P6_CONTRACT_LIMITS = {
    date: 40,
    startDate: 40,
    endDate: 40,
    tnum: 64,
    orderNum: 64,
    address: 512,
    code: 64,
    name: 128,
    status: 64,
    service: 128,
    role: 64,
    message: 1024,
    currency: 16,
    datetime: 40,
    orderNo: 64
};
function enforceCurrencyListContract(items, fieldPrefix = 'currency.response') {
    return items.map((item, index) => ({
        code: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].code`, item.code, exports.P6_CONTRACT_LIMITS.code),
        name: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].name`, item.name, exports.P6_CONTRACT_LIMITS.name),
        status: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].status`, item.status, exports.P6_CONTRACT_LIMITS.status),
        service: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].service`, item.service, exports.P6_CONTRACT_LIMITS.service),
        role: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].role`, item.role, exports.P6_CONTRACT_LIMITS.role),
        message: item.message == null ? null : (0, p1_contract_policy_1.truncateMax)(item.message, exports.P6_CONTRACT_LIMITS.message),
        currency: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].currency`, item.currency, exports.P6_CONTRACT_LIMITS.currency),
        orderNo: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].orderNo`, item.orderNo, exports.P6_CONTRACT_LIMITS.orderNo),
        address: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].address`, item.address, exports.P6_CONTRACT_LIMITS.address),
        date: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].date`, item.date, exports.P6_CONTRACT_LIMITS.datetime),
        amount: ensureOptionalNumber(`${fieldPrefix}[${index}].amount`, item.amount),
        balance: ensureOptionalNumber(`${fieldPrefix}[${index}].balance`, item.balance)
    }));
}
function ensureOptionalNumber(field, value) {
    if (value == null) {
        return null;
    }
    if (typeof value !== 'number' || Number.isNaN(value)) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be number or null.`);
    }
    return value;
}
//# sourceMappingURL=p6-contract-policy.js.map