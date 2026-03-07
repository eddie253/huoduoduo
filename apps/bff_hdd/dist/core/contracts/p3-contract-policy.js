"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P3_CONTRACT_LIMITS = void 0;
exports.enforceReservationListContract = enforceReservationListContract;
exports.enforceReservationCreateContract = enforceReservationCreateContract;
const legacy_soap_error_1 = require("../../adapters/soap/legacy-soap.error");
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P3_CONTRACT_LIMITS = {
    reservationNo: 64,
    address: 512,
    shipmentNo: 64,
    shipmentNosMaxItems: 200,
    mode: 16,
    areaCode: 64,
    note: 1024
};
function enforceReservationListContract(reservations, fieldPrefix = 'reservations.list.response') {
    return reservations.map((item, index) => enforceReservationItemContract(item, `${fieldPrefix}[${index}]`));
}
function enforceReservationCreateContract(result, fieldPrefix = 'reservations.create.response') {
    const reservationNo = (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.reservationNo`, result.reservationNo, exports.P3_CONTRACT_LIMITS.reservationNo);
    const mode = ensureReservationMode(result.mode, `${fieldPrefix}.mode`);
    return {
        reservationNo,
        mode
    };
}
function enforceReservationItemContract(item, fieldPrefix) {
    (0, p1_contract_policy_1.ensureMaxItems)(`${fieldPrefix}.shipmentNos`, item.shipmentNos.length, exports.P3_CONTRACT_LIMITS.shipmentNosMaxItems);
    return {
        reservationNo: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.reservationNo`, item.reservationNo, exports.P3_CONTRACT_LIMITS.reservationNo),
        address: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.address`, item.address, exports.P3_CONTRACT_LIMITS.address),
        fee: ensureReservationFee(item.fee, `${fieldPrefix}.fee`),
        shipmentNos: item.shipmentNos.map((shipmentNo, index) => (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.shipmentNos[${index}]`, shipmentNo, exports.P3_CONTRACT_LIMITS.shipmentNo)),
        mode: ensureReservationMode(item.mode, `${fieldPrefix}.mode`)
    };
}
function ensureReservationMode(mode, field) {
    (0, p1_contract_policy_1.ensureMax)(field, mode, exports.P3_CONTRACT_LIMITS.mode);
    if (mode !== 'standard' && mode !== 'bulk') {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} invalid value: ${mode}`);
    }
    return mode;
}
function ensureReservationFee(fee, field) {
    if (fee == null) {
        return null;
    }
    if (typeof fee !== 'number' || Number.isNaN(fee)) {
        throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, `${field} must be number or null.`);
    }
    return fee;
}
//# sourceMappingURL=p3-contract-policy.js.map