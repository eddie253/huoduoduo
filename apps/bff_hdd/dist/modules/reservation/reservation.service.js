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
exports.ReservationService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const p3_contract_policy_1 = require("../../core/contracts/p3-contract-policy");
const p7_contract_policy_1 = require("../../core/contracts/p7-contract-policy");
let ReservationService = class ReservationService {
    constructor(legacySoapClient) {
        this.legacySoapClient = legacySoapClient;
    }
    async listReservations(mode, claims) {
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.list.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const reservations = await this.legacySoapClient.listReservations(mode, normalizedContractNo);
        return (0, p3_contract_policy_1.enforceReservationListContract)(reservations);
    }
    async createReservation(mode, dto, claims) {
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.create.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const normalizedAddress = (0, p1_contract_policy_1.ensureMax)('reservations.create.request.address', dto.address, p3_contract_policy_1.P3_CONTRACT_LIMITS.address);
        const normalizedShipmentNos = dto.shipmentNos.map((shipmentNo, index) => (0, p1_contract_policy_1.ensureMax)(`reservations.create.request.shipmentNos[${index}]`, shipmentNo, p3_contract_policy_1.P3_CONTRACT_LIMITS.shipmentNo));
        const created = await this.legacySoapClient.createReservation(mode, {
            contractNo: normalizedContractNo,
            address: normalizedAddress,
            shipmentNos: normalizedShipmentNos,
            fee: dto.fee
        });
        return (0, p3_contract_policy_1.enforceReservationCreateContract)(created);
    }
    async deleteReservation(mode, id, address, claims) {
        const normalizedId = (0, p1_contract_policy_1.ensureMax)('reservations.delete.request.id', id, p3_contract_policy_1.P3_CONTRACT_LIMITS.reservationNo);
        const normalizedAddress = (0, p1_contract_policy_1.ensureMax)('reservations.delete.request.address', address, p3_contract_policy_1.P3_CONTRACT_LIMITS.address);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.delete.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        await this.legacySoapClient.deleteReservation(mode, normalizedId, normalizedAddress, normalizedContractNo);
        return { ok: true };
    }
    async getZipAreas() {
        const rows = await this.legacySoapClient.getReservationZipAreas();
        return {
            items: (0, p7_contract_policy_1.enforceReservationSupportListContract)(rows, 'reservations.zip-areas.response')
        };
    }
    async getAvailable(zip, claims) {
        const normalizedZip = (0, p1_contract_policy_1.ensureMax)('reservations.available.request.zip', zip, p7_contract_policy_1.P7_CONTRACT_LIMITS.zip);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.available.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getReservationAvailable(normalizedZip, normalizedContractNo);
        return {
            items: (0, p7_contract_policy_1.enforceReservationSupportListContract)(rows, 'reservations.available.response')
        };
    }
    async getAvailableBulk(zip, claims) {
        const normalizedZip = (0, p1_contract_policy_1.ensureMax)('reservations.available.bulk.request.zip', zip, p7_contract_policy_1.P7_CONTRACT_LIMITS.zip);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.available.bulk.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getReservationAvailableBulk(normalizedZip, normalizedContractNo);
        return {
            items: (0, p7_contract_policy_1.enforceReservationSupportListContract)(rows, 'reservations.available.bulk.response')
        };
    }
    async getAreaCodes(claims) {
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.area-codes.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getReservationAreaCodes(normalizedContractNo);
        return {
            items: (0, p7_contract_policy_1.enforceReservationSupportListContract)(rows, 'reservations.area-codes.response')
        };
    }
    async getArrived(claims) {
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('reservations.arrived.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getReservationArrived(normalizedContractNo);
        return {
            items: (0, p7_contract_policy_1.enforceReservationSupportListContract)(rows, 'reservations.arrived.response')
        };
    }
};
exports.ReservationService = ReservationService;
exports.ReservationService = ReservationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [legacy_soap_client_1.LegacySoapClient])
], ReservationService);
//# sourceMappingURL=reservation.service.js.map