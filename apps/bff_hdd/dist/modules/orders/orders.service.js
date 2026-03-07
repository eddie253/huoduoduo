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
exports.OrdersService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const legacy_soap_error_1 = require("../../adapters/soap/legacy-soap.error");
const idempotency_guard_service_1 = require("../../shared/idempotency/idempotency-guard.service");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const p2_contract_policy_1 = require("../../core/contracts/p2-contract-policy");
const IDEMPOTENCY_TTL_SECONDS = 86400;
let OrdersService = class OrdersService {
    constructor(legacySoapClient, idempotencyGuard) {
        this.legacySoapClient = legacySoapClient;
        this.idempotencyGuard = idempotencyGuard;
    }
    async acceptOrder(trackingNo, claims, idempotencyKey) {
        if (!idempotencyKey) {
            throw new common_1.BadRequestException('X-Idempotency-Key header is required');
        }
        const normalizedTrackingNo = (0, p1_contract_policy_1.ensureMax)('orders.accept.request.trackingNo', trackingNo, p2_contract_policy_1.P2_CONTRACT_LIMITS.trackingNo);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('orders.accept.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const isUnique = await this.idempotencyGuard.ensureUnique(`order_accept:${normalizedTrackingNo}`, idempotencyKey, IDEMPOTENCY_TTL_SECONDS);
        if (!isUnique) {
            throw new common_1.ConflictException({
                code: 'ORDER_ALREADY_TAKEN',
                message: 'This order has already been accepted'
            });
        }
        try {
            await this.legacySoapClient.acceptOrder(normalizedContractNo, normalizedTrackingNo);
            return { ok: true };
        }
        catch (error) {
            if (error instanceof legacy_soap_error_1.LegacySoapError) {
                const errorMessage = error.message.toLowerCase();
                if (errorMessage.includes('already') || errorMessage.includes('已被')) {
                    throw new common_1.ConflictException({
                        code: 'ORDER_ALREADY_TAKEN',
                        message: 'This order has already been accepted by another driver'
                    });
                }
            }
            throw error;
        }
    }
};
exports.OrdersService = OrdersService;
exports.OrdersService = OrdersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [legacy_soap_client_1.LegacySoapClient,
        idempotency_guard_service_1.IdempotencyGuardService])
], OrdersService);
//# sourceMappingURL=orders.service.js.map