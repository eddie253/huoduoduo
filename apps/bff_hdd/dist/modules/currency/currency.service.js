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
exports.CurrencyService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const p6_contract_policy_1 = require("../../core/contracts/p6-contract-policy");
let CurrencyService = class CurrencyService {
    constructor(legacySoapClient) {
        this.legacySoapClient = legacySoapClient;
    }
    async getDaily(date, claims) {
        const normalizedDate = (0, p1_contract_policy_1.ensureMax)('currency.daily.request.date', date, p6_contract_policy_1.P6_CONTRACT_LIMITS.date);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('currency.daily.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getDriverCurrency(normalizedDate, normalizedContractNo);
        return { items: (0, p6_contract_policy_1.enforceCurrencyListContract)(rows, 'currency.daily.response') };
    }
    async getMonthly(date, claims) {
        const normalizedDate = (0, p1_contract_policy_1.ensureMax)('currency.monthly.request.date', date, p6_contract_policy_1.P6_CONTRACT_LIMITS.date);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('currency.monthly.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getDriverCurrencyMonth(normalizedDate, normalizedContractNo);
        return { items: (0, p6_contract_policy_1.enforceCurrencyListContract)(rows, 'currency.monthly.response') };
    }
    async getBalance(claims) {
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('currency.balance.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getDriverBalance(normalizedContractNo);
        return { items: (0, p6_contract_policy_1.enforceCurrencyListContract)(rows, 'currency.balance.response') };
    }
    async getDepositHead(startDate, endDate, claims) {
        const normalizedStartDate = (0, p1_contract_policy_1.ensureMax)('currency.deposit.head.request.startDate', startDate, p6_contract_policy_1.P6_CONTRACT_LIMITS.startDate);
        const normalizedEndDate = (0, p1_contract_policy_1.ensureMax)('currency.deposit.head.request.endDate', endDate, p6_contract_policy_1.P6_CONTRACT_LIMITS.endDate);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('currency.deposit.head.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getDepositHead(normalizedStartDate, normalizedEndDate, normalizedContractNo);
        return { items: (0, p6_contract_policy_1.enforceCurrencyListContract)(rows, 'currency.deposit.head.response') };
    }
    async getDepositBody(tnum, address, claims) {
        const normalizedTnum = (0, p1_contract_policy_1.ensureMax)('currency.deposit.body.request.tnum', tnum, p6_contract_policy_1.P6_CONTRACT_LIMITS.tnum);
        const normalizedAddress = (0, p1_contract_policy_1.ensureMax)('currency.deposit.body.request.address', address, p6_contract_policy_1.P6_CONTRACT_LIMITS.address);
        const normalizedContractNo = (0, p1_contract_policy_1.ensureMax)('currency.deposit.body.request.contractNo', claims.contractNo, p1_contract_policy_1.P1_CONTRACT_LIMITS.contractNo);
        const rows = await this.legacySoapClient.getDepositBody(normalizedTnum, normalizedAddress, normalizedContractNo);
        return { items: (0, p6_contract_policy_1.enforceCurrencyListContract)(rows, 'currency.deposit.body.response') };
    }
    async getShipmentCurrency(orderNum) {
        const normalizedOrderNum = (0, p1_contract_policy_1.ensureMax)('currency.shipment.request.orderNum', orderNum, p6_contract_policy_1.P6_CONTRACT_LIMITS.orderNum);
        const rows = await this.legacySoapClient.getShipmentCurrency(normalizedOrderNum);
        return { items: (0, p6_contract_policy_1.enforceCurrencyListContract)(rows, 'currency.shipment.response') };
    }
};
exports.CurrencyService = CurrencyService;
exports.CurrencyService = CurrencyService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [legacy_soap_client_1.LegacySoapClient])
], CurrencyService);
//# sourceMappingURL=currency.service.js.map