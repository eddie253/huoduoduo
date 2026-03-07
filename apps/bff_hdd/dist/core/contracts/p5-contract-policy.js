"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P5_CONTRACT_LIMITS = void 0;
exports.enforceProxyMateListContract = enforceProxyMateListContract;
exports.enforceProxyKpiListContract = enforceProxyKpiListContract;
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P5_CONTRACT_LIMITS = {
    area: 64,
    year: 4,
    month: 2,
    date: 10,
    code: 64,
    status: 64,
    role: 64,
    name: 128,
    service: 128,
    message: 1024,
    datetime: 40
};
function enforceProxyMateListContract(items, fieldPrefix = 'proxy.mates.response') {
    return items.map((item, index) => ({
        code: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].code`, item.code, exports.P5_CONTRACT_LIMITS.code),
        name: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].name`, item.name, exports.P5_CONTRACT_LIMITS.name),
        area: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].area`, item.area, exports.P5_CONTRACT_LIMITS.area),
        status: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].status`, item.status, exports.P5_CONTRACT_LIMITS.status),
        service: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].service`, item.service, exports.P5_CONTRACT_LIMITS.service),
        role: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].role`, item.role, exports.P5_CONTRACT_LIMITS.role),
        message: item.message == null ? null : (0, p1_contract_policy_1.truncateMax)(item.message, exports.P5_CONTRACT_LIMITS.message),
        updatedAt: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].updatedAt`, item.updatedAt, exports.P5_CONTRACT_LIMITS.datetime)
    }));
}
function enforceProxyKpiListContract(items, fieldPrefix = 'proxy.kpi.response') {
    return items.map((item, index) => ({
        code: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].code`, item.code, exports.P5_CONTRACT_LIMITS.code),
        name: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].name`, item.name, exports.P5_CONTRACT_LIMITS.name),
        status: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].status`, item.status, exports.P5_CONTRACT_LIMITS.status),
        service: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].service`, item.service, exports.P5_CONTRACT_LIMITS.service),
        role: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].role`, item.role, exports.P5_CONTRACT_LIMITS.role),
        message: item.message == null ? null : (0, p1_contract_policy_1.truncateMax)(item.message, exports.P5_CONTRACT_LIMITS.message),
        updatedAt: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].updatedAt`, item.updatedAt, exports.P5_CONTRACT_LIMITS.datetime)
    }));
}
//# sourceMappingURL=p5-contract-policy.js.map