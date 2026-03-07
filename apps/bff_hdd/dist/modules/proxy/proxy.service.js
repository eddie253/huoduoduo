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
exports.ProxyService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const p5_contract_policy_1 = require("../../core/contracts/p5-contract-policy");
let ProxyService = class ProxyService {
    constructor(legacySoapClient) {
        this.legacySoapClient = legacySoapClient;
    }
    async getMates(area) {
        const normalizedArea = (0, p1_contract_policy_1.ensureMax)('proxy.mates.request.area', area, p5_contract_policy_1.P5_CONTRACT_LIMITS.area);
        const rows = await this.legacySoapClient.getProxyMates(normalizedArea);
        return {
            items: (0, p5_contract_policy_1.enforceProxyMateListContract)(rows)
        };
    }
    async searchKpi(year, month, area) {
        const normalizedYear = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.search.request.year', year, p5_contract_policy_1.P5_CONTRACT_LIMITS.year);
        const normalizedMonth = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.search.request.month', month, p5_contract_policy_1.P5_CONTRACT_LIMITS.month);
        const normalizedArea = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.search.request.area', area, p5_contract_policy_1.P5_CONTRACT_LIMITS.area);
        const rows = await this.legacySoapClient.searchProxyKpi(normalizedYear, normalizedMonth, normalizedArea);
        return {
            items: (0, p5_contract_policy_1.enforceProxyKpiListContract)(rows, 'proxy.kpi.search.response')
        };
    }
    async getKpi(year, month, area) {
        const normalizedYear = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.request.year', year, p5_contract_policy_1.P5_CONTRACT_LIMITS.year);
        const normalizedMonth = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.request.month', month, p5_contract_policy_1.P5_CONTRACT_LIMITS.month);
        const normalizedArea = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.request.area', area, p5_contract_policy_1.P5_CONTRACT_LIMITS.area);
        const rows = await this.legacySoapClient.getProxyKpi(normalizedYear, normalizedMonth, normalizedArea);
        return {
            items: (0, p5_contract_policy_1.enforceProxyKpiListContract)(rows, 'proxy.kpi.response')
        };
    }
    async getKpiDaily(date, area) {
        const normalizedDate = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.daily.request.date', date, p5_contract_policy_1.P5_CONTRACT_LIMITS.date);
        const normalizedArea = (0, p1_contract_policy_1.ensureMax)('proxy.kpi.daily.request.area', area, p5_contract_policy_1.P5_CONTRACT_LIMITS.area);
        const rows = await this.legacySoapClient.getProxyKpiDaily(normalizedDate, normalizedArea);
        return {
            items: (0, p5_contract_policy_1.enforceProxyKpiListContract)(rows, 'proxy.kpi.daily.response')
        };
    }
};
exports.ProxyService = ProxyService;
exports.ProxyService = ProxyService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [legacy_soap_client_1.LegacySoapClient])
], ProxyService);
//# sourceMappingURL=proxy.service.js.map