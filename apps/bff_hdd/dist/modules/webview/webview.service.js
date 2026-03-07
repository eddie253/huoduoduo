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
exports.WebviewService = void 0;
const common_1 = require("@nestjs/common");
const legacy_soap_client_1 = require("../../adapters/soap/legacy-soap.client");
const p1_contract_policy_1 = require("../../core/contracts/p1-contract-policy");
const auth_service_1 = require("../auth/auth.service");
let WebviewService = class WebviewService {
    constructor(authService, legacySoapClient) {
        this.authService = authService;
        this.legacySoapClient = legacySoapClient;
    }
    getBootstrap(account, identify) {
        return this.authService.getWebviewBootstrap(account, identify);
    }
    async getCurrentBulletin() {
        const bulletins = await this.legacySoapClient.getBulletins();
        const current = bulletins[0];
        if (!current) {
            return {
                message: '',
                hasAnnouncement: false,
                updatedAt: null
            };
        }
        return {
            message: (0, p1_contract_policy_1.truncateMax)(current.title, p1_contract_policy_1.P1_CONTRACT_LIMITS.bulletinMessage),
            hasAnnouncement: true,
            updatedAt: (0, p1_contract_policy_1.ensureIsoDatetime)('bootstrap.bulletin.updatedAt', current.date, p1_contract_policy_1.P1_CONTRACT_LIMITS.datetime)
        };
    }
};
exports.WebviewService = WebviewService;
exports.WebviewService = WebviewService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [auth_service_1.AuthService,
        legacy_soap_client_1.LegacySoapClient])
], WebviewService);
//# sourceMappingURL=webview.service.js.map