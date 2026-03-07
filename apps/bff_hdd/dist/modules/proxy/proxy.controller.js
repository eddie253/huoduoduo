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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProxyController = void 0;
const common_1 = require("@nestjs/common");
const no_store_response_decorator_1 = require("../../security/no-store-response.decorator");
const proxy_query_dto_1 = require("./dto/proxy-query.dto");
const proxy_service_1 = require("./proxy.service");
let ProxyController = class ProxyController {
    constructor(proxyService) {
        this.proxyService = proxyService;
    }
    getMates(query) {
        return this.proxyService.getMates(query.area);
    }
    searchKpi(query) {
        return this.proxyService.searchKpi(query.year, query.month, query.area);
    }
    getKpi(query) {
        return this.proxyService.getKpi(query.year, query.month, query.area);
    }
    getKpiDaily(query) {
        return this.proxyService.getKpiDaily(query.date, query.area);
    }
};
exports.ProxyController = ProxyController;
__decorate([
    (0, common_1.Get)('mates'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [proxy_query_dto_1.ProxyAreaQueryDto]),
    __metadata("design:returntype", Promise)
], ProxyController.prototype, "getMates", null);
__decorate([
    (0, common_1.Get)('kpi/search'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [proxy_query_dto_1.ProxyKpiQueryDto]),
    __metadata("design:returntype", Promise)
], ProxyController.prototype, "searchKpi", null);
__decorate([
    (0, common_1.Get)('kpi'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [proxy_query_dto_1.ProxyKpiQueryDto]),
    __metadata("design:returntype", Promise)
], ProxyController.prototype, "getKpi", null);
__decorate([
    (0, common_1.Get)('kpi/daily'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [proxy_query_dto_1.ProxyKpiDailyQueryDto]),
    __metadata("design:returntype", Promise)
], ProxyController.prototype, "getKpiDaily", null);
exports.ProxyController = ProxyController = __decorate([
    (0, no_store_response_decorator_1.NoStoreResponse)(),
    (0, common_1.Controller)('proxy'),
    __metadata("design:paramtypes", [proxy_service_1.ProxyService])
], ProxyController);
//# sourceMappingURL=proxy.controller.js.map