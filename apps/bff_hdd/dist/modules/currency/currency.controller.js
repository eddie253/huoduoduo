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
exports.CurrencyController = void 0;
const common_1 = require("@nestjs/common");
const no_store_response_decorator_1 = require("../../security/no-store-response.decorator");
const currency_query_dto_1 = require("./dto/currency-query.dto");
const currency_service_1 = require("./currency.service");
let CurrencyController = class CurrencyController {
    constructor(currencyService) {
        this.currencyService = currencyService;
    }
    getDaily(request, query) {
        const claims = request.user;
        return this.currencyService.getDaily(query.date, claims);
    }
    getMonthly(request, query) {
        const claims = request.user;
        return this.currencyService.getMonthly(query.date, claims);
    }
    getBalance(request) {
        const claims = request.user;
        return this.currencyService.getBalance(claims);
    }
    getDepositHead(request, query) {
        const claims = request.user;
        return this.currencyService.getDepositHead(query.startDate, query.endDate, claims);
    }
    getDepositBody(request, query) {
        const claims = request.user;
        return this.currencyService.getDepositBody(query.tnum, query.address, claims);
    }
    getShipmentCurrency(query) {
        return this.currencyService.getShipmentCurrency(query.orderNum);
    }
};
exports.CurrencyController = CurrencyController;
__decorate([
    (0, common_1.Get)('daily'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, currency_query_dto_1.CurrencyDateQueryDto]),
    __metadata("design:returntype", Promise)
], CurrencyController.prototype, "getDaily", null);
__decorate([
    (0, common_1.Get)('monthly'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, currency_query_dto_1.CurrencyDateQueryDto]),
    __metadata("design:returntype", Promise)
], CurrencyController.prototype, "getMonthly", null);
__decorate([
    (0, common_1.Get)('balance'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CurrencyController.prototype, "getBalance", null);
__decorate([
    (0, common_1.Get)('deposit/head'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, currency_query_dto_1.CurrencyDepositHeadQueryDto]),
    __metadata("design:returntype", Promise)
], CurrencyController.prototype, "getDepositHead", null);
__decorate([
    (0, common_1.Get)('deposit/body'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, currency_query_dto_1.CurrencyDepositBodyQueryDto]),
    __metadata("design:returntype", Promise)
], CurrencyController.prototype, "getDepositBody", null);
__decorate([
    (0, common_1.Get)('shipment'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [currency_query_dto_1.CurrencyShipmentQueryDto]),
    __metadata("design:returntype", Promise)
], CurrencyController.prototype, "getShipmentCurrency", null);
exports.CurrencyController = CurrencyController = __decorate([
    (0, no_store_response_decorator_1.NoStoreResponse)(),
    (0, common_1.Controller)('currency'),
    __metadata("design:paramtypes", [currency_service_1.CurrencyService])
], CurrencyController);
//# sourceMappingURL=currency.controller.js.map