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
exports.SystemService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const p9_contract_policy_1 = require("../../core/contracts/p9-contract-policy");
let SystemService = class SystemService {
    constructor(legacySoapClient) {
        this.legacySoapClient = legacySoapClient;
    }
    async getVersion(name) {
        const normalizedName = (0, p1_contract_policy_1.ensureMax)('system.version.request.name', name, p9_contract_policy_1.P9_CONTRACT_LIMITS.versionName);
        const raw = await this.legacySoapClient.getVersion(normalizedName);
        const versionCode = (0, p9_contract_policy_1.parseLegacyVersionCode)(raw);
        return (0, p9_contract_policy_1.enforceSystemVersionResponseContract)({
            name: normalizedName,
            versionCode
        });
    }
};
exports.SystemService = SystemService;
exports.SystemService = SystemService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [legacy_soap_client_1.LegacySoapClient])
], SystemService);
//# sourceMappingURL=system.service.js.map