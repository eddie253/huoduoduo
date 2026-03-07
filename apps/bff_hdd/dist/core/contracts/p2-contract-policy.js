"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.P2_CONTRACT_LIMITS = void 0;
exports.enforceShipmentResponseContract = enforceShipmentResponseContract;
const p1_contract_policy_1 = require("./p1-contract-policy");
exports.P2_CONTRACT_LIMITS = {
    trackingNo: 32,
    recipient: 128,
    address: 512,
    phone: 32,
    mobile: 32,
    zipCode: 16,
    city: 64,
    district: 64,
    status: 64,
    signedAt: 40,
    signedImageFileName: 255,
    signedLocation: 64
};
function enforceShipmentResponseContract(shipment, fieldPrefix = 'shipments.get.response') {
    return {
        trackingNo: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.trackingNo`, shipment.trackingNo, exports.P2_CONTRACT_LIMITS.trackingNo),
        recipient: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.recipient`, shipment.recipient, exports.P2_CONTRACT_LIMITS.recipient),
        address: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.address`, shipment.address, exports.P2_CONTRACT_LIMITS.address),
        phone: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.phone`, shipment.phone, exports.P2_CONTRACT_LIMITS.phone),
        mobile: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.mobile`, shipment.mobile, exports.P2_CONTRACT_LIMITS.mobile),
        zipCode: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.zipCode`, shipment.zipCode, exports.P2_CONTRACT_LIMITS.zipCode),
        city: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.city`, shipment.city, exports.P2_CONTRACT_LIMITS.city),
        district: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.district`, shipment.district, exports.P2_CONTRACT_LIMITS.district),
        status: (0, p1_contract_policy_1.ensureMax)(`${fieldPrefix}.status`, shipment.status, exports.P2_CONTRACT_LIMITS.status),
        signedAt: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}.signedAt`, shipment.signedAt, exports.P2_CONTRACT_LIMITS.signedAt),
        signedImageFileName: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}.signedImageFileName`, shipment.signedImageFileName, exports.P2_CONTRACT_LIMITS.signedImageFileName),
        signedLocation: (0, p1_contract_policy_1.ensureOptionalMax)(`${fieldPrefix}.signedLocation`, shipment.signedLocation, exports.P2_CONTRACT_LIMITS.signedLocation)
    };
}
//# sourceMappingURL=p2-contract-policy.js.map