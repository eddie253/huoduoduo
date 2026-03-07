"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P7_CONTRACT_LIMITS = void 0;
exports.enforceReservationSupportListContract = enforceReservationSupportListContract;
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P7_CONTRACT_LIMITS = {
    zip: 64,
    code: 64,
    status: 64,
    role: 64,
    name: 128,
    service: 128,
    message: 1024,
    reservationNo: 64,
    trackingNo: 64,
    areaCode: 64,
    address: 512,
    datetime: 40
};
function enforceReservationSupportListContract(items, fieldPrefix = 'reservations.support.response') {
    return items.map((item, index) => ({
        code: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].code`, item.code, exports.P7_CONTRACT_LIMITS.code),
        name: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}[${index}].name`, item.name, exports.P7_CONTRACT_LIMITS.name),
        status: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].status`, item.status, exports.P7_CONTRACT_LIMITS.status),
        service: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].service`, item.service, exports.P7_CONTRACT_LIMITS.service),
        role: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].role`, item.role, exports.P7_CONTRACT_LIMITS.role),
        message: item.message == null ? null : (0, p1_contract_policy_1.truncateMax)(item.message, exports.P7_CONTRACT_LIMITS.message),
        reservationNo: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].reservationNo`, item.reservationNo, exports.P7_CONTRACT_LIMITS.reservationNo),
        trackingNo: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].trackingNo`, item.trackingNo, exports.P7_CONTRACT_LIMITS.trackingNo),
        zip: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].zip`, item.zip, exports.P7_CONTRACT_LIMITS.zip),
        areaCode: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].areaCode`, item.areaCode, exports.P7_CONTRACT_LIMITS.areaCode),
        address: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].address`, item.address, exports.P7_CONTRACT_LIMITS.address),
        date: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}[${index}].date`, item.date, exports.P7_CONTRACT_LIMITS.datetime)
    }));
}
//# sourceMappingURL=p7-contract-policy.js.map