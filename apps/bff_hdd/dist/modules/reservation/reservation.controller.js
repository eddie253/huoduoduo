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
exports.ReservationController = void 0;
const common_1 = require("@nestjs/common");
const create_reservation_dto_1 = require("./dto/create-reservation.dto");
const reservation_support_query_dto_1 = require("./dto/reservation-support-query.dto");
const reservation_param_dto_1 = require("./dto/reservation-param.dto");
const reservation_query_dto_1 = require("./dto/reservation-query.dto");
const reservation_service_1 = require("./reservation.service");
const no_store_response_decorator_1 = require("../../security/no-store-response.decorator");
let ReservationController = class ReservationController {
    constructor(reservationService) {
        this.reservationService = reservationService;
    }
    listReservations(request, query) {
        const claims = request.user;
        const mode = query.mode ?? 'standard';
        return this.reservationService.listReservations(mode, claims);
    }
    getZipAreas() {
        return this.reservationService.getZipAreas();
    }
    getAvailable(request, query) {
        const claims = request.user;
        return this.reservationService.getAvailable(query.zip, claims);
    }
    getAvailableBulk(request, query) {
        const claims = request.user;
        return this.reservationService.getAvailableBulk(query.zip, claims);
    }
    getAreaCodes(request) {
        const claims = request.user;
        return this.reservationService.getAreaCodes(claims);
    }
    getArrived(request) {
        const claims = request.user;
        return this.reservationService.getArrived(claims);
    }
    createReservation(request, query, dto) {
        const claims = request.user;
        const mode = query.mode ?? 'standard';
        return this.reservationService.createReservation(mode, dto, claims);
    }
    deleteReservation(request, param, query) {
        const claims = request.user;
        const mode = query.mode ?? 'standard';
        return this.reservationService.deleteReservation(mode, param.id, query.address, claims);
    }
};
exports.ReservationController = ReservationController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, reservation_query_dto_1.ReservationQueryDto]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "listReservations", null);
__decorate([
    (0, common_1.Get)('zip-areas'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "getZipAreas", null);
__decorate([
    (0, common_1.Get)('available'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, reservation_support_query_dto_1.ReservationSupportZipQueryDto]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "getAvailable", null);
__decorate([
    (0, common_1.Get)('available/bulk'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, reservation_support_query_dto_1.ReservationSupportZipQueryDto]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "getAvailableBulk", null);
__decorate([
    (0, common_1.Get)('area-codes'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "getAreaCodes", null);
__decorate([
    (0, common_1.Get)('arrived'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "getArrived", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.HttpCode)(200),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, reservation_query_dto_1.ReservationQueryDto,
        create_reservation_dto_1.CreateReservationDto]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "createReservation", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)()),
    __param(2, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, reservation_param_dto_1.ReservationParamDto,
        reservation_query_dto_1.DeleteReservationQueryDto]),
    __metadata("design:returntype", Promise)
], ReservationController.prototype, "deleteReservation", null);
exports.ReservationController = ReservationController = __decorate([
    (0, no_store_response_decorator_1.NoStoreResponse)(),
    (0, common_1.Controller)('reservations'),
    __metadata("design:paramtypes", [reservation_service_1.ReservationService])
], ReservationController);
//# sourceMappingURL=reservation.controller.js.map