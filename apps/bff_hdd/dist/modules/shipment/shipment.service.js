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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShipmentService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const p2_contract_policy_1 = require("../../core/contracts/p2-contract-policy");
const idempotency_guard_service_1 = require("../../shared/idempotency/idempotency-guard.service");
let ShipmentService = class ShipmentService {
    constructor(legacySoapClient, idempotencyGuardService) {
        this.legacySoapClient = legacySoapClient;
        this.idempotencyGuardService = idempotencyGuardService;
    }
    async getShipment(trackingNo) {
        const normalizedTrackingNo = (0, p1_contract_policy_1.ensureMax)('shipments.get.request.trackingNo', trackingNo, p2_contract_policy_1.P2_CONTRACT_LIMITS.trackingNo);
        const shipment = await this.legacySoapClient.getShipment(normalizedTrackingNo);
        return (0, p2_contract_policy_1.enforceShipmentResponseContract)(shipment);
    }
    async submitDelivery(trackingNo, dto, claims, idempotencyKey) {
        const normalizedTrackingNo = (0, p1_contract_policy_1.ensureMax)('shipments.delivery.request.trackingNo', trackingNo, p2_contract_policy_1.P2_CONTRACT_LIMITS.trackingNo);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('shipments.delivery.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        if (idempotencyKey) {
            const accepted = await this.idempotencyGuardService.ensureUnique(`delivery:${normalizedTrackingNo}`, idempotencyKey, 60 * 60 * 24);
            if (!accepted) {
                throw new common_1.ConflictException({ code: 'DELIVERY_DUPLICATE' });
            }
        }
        if (dto.signatureBase64) {
            await this.legacySoapClient.uploadSignature(normalizedTrackingNo, {
                contractNo: normalizedContractNo,
                signatureBase64: dto.signatureBase64
            });
        }
        await this.legacySoapClient.submitShipmentDelivery(normalizedTrackingNo, {
            contractNo: normalizedContractNo,
            imageBase64: dto.imageBase64,
            imageFileName: dto.imageFileName,
            latitude: dto.latitude,
            longitude: dto.longitude
        });
        return { ok: true };
    }
    async submitException(trackingNo, dto, claims, idempotencyKey) {
        const normalizedTrackingNo = (0, p1_contract_policy_1.ensureMax)('shipments.exception.request.trackingNo', trackingNo, p2_contract_policy_1.P2_CONTRACT_LIMITS.trackingNo);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('shipments.exception.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        if (idempotencyKey) {
            const accepted = await this.idempotencyGuardService.ensureUnique(`exception:${normalizedTrackingNo}`, idempotencyKey, 60 * 60 * 24);
            if (!accepted) {
                throw new common_1.ConflictException({ code: 'DELIVERY_DUPLICATE' });
            }
        }
        await this.legacySoapClient.submitShipmentException(normalizedTrackingNo, {
            contractNo: normalizedContractNo,
            imageBase64: dto.imageBase64,
            imageFileName: dto.imageFileName,
            latitude: dto.latitude,
            longitude: dto.longitude
        });
        return { ok: true };
    }
};
exports.ShipmentService = ShipmentService;
exports.ShipmentService = ShipmentService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [legacy_soap_client_1.LegacySoapClient,
        idempotency_guard_service_1.IdempotencyGuardService])
], ShipmentService);
//# sourceMappingURL=shipment.service.js.map