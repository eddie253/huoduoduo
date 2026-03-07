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
exports.DriverLocationController = void 0;
const common_1 = require("@nestjs/common");
const driver_location_dto_1 = require("./dto/driver-location.dto");
const driver_location_service_1 = require("./driver-location.service");
let DriverLocationController = class DriverLocationController {
    constructor(driverLocationService) {
        this.driverLocationService = driverLocationService;
    }
    submitLocation(dto) {
        return this.driverLocationService.submitLocation(dto);
    }
    submitLocationsBatch(dtts) {
        return this.driverLocationService.submitLocationsBatch(dtts);
    }
};
exports.DriverLocationController = DriverLocationController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [driver_location_dto_1.DriverLocationDto]),
    __metadata("design:returntype", Promise)
], DriverLocationController.prototype, "submitLocation", null);
__decorate([
    (0, common_1.Post)('batch'),
    __param(0, (0, common_1.Body)(new common_1.ParseArrayPipe({
        items: driver_location_dto_1.DriverLocationDto,
        whitelist: true,
        forbidNonWhitelisted: true
    }))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Array]),
    __metadata("design:returntype", Promise)
], DriverLocationController.prototype, "submitLocationsBatch", null);
exports.DriverLocationController = DriverLocationController = __decorate([
    (0, common_1.Controller)('drivers/location'),
    __metadata("design:paramtypes", [driver_location_service_1.DriverLocationService])
], DriverLocationController);
//# sourceMappingURL=driver-location.controller.js.map