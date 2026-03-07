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
exports.ShipmentController = void 0;
const common_1 = require("@nestjs/common");
const delivery_request_dto_1 = require("./dto/delivery-request.dto");
const exception_request_dto_1 = require("./dto/exception-request.dto");
const shipment_service_1 = require("./shipment.service");
const no_store_response_decorator_1 = require("../../security/no-store-response.decorator");
let ShipmentController = class ShipmentController {
    constructor(shipmentService) {
        this.shipmentService = shipmentService;
    }
    getShipment(trackingNo) {
        return this.shipmentService.getShipment(trackingNo);
    }
    submitDelivery(request, trackingNo, dto, idempotencyKey) {
        const claims = request.user;
        return this.shipmentService.submitDelivery(trackingNo, dto, claims, idempotencyKey);
    }
    submitException(request, trackingNo, dto, idempotencyKey) {
        const claims = request.user;
        return this.shipmentService.submitException(trackingNo, dto, claims, idempotencyKey);
    }
};
exports.ShipmentController = ShipmentController;
__decorate([
    (0, common_1.Get)(':trackingNo'),
    __param(0, (0, common_1.Param)('trackingNo')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ShipmentController.prototype, "getShipment", null);
__decorate([
    (0, common_1.Post)(':trackingNo/delivery'),
    (0, common_1.HttpCode)(200),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('trackingNo')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Headers)('x-idempotency-key')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, delivery_request_dto_1.DeliveryRequestDto, String]),
    __metadata("design:returntype", Promise)
], ShipmentController.prototype, "submitDelivery", null);
__decorate([
    (0, common_1.Post)(':trackingNo/exception'),
    (0, common_1.HttpCode)(200),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('trackingNo')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Headers)('x-idempotency-key')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, exception_request_dto_1.ExceptionRequestDto, String]),
    __metadata("design:returntype", Promise)
], ShipmentController.prototype, "submitException", null);
exports.ShipmentController = ShipmentController = __decorate([
    (0, no_store_response_decorator_1.NoStoreResponse)(),
    (0, common_1.Controller)('shipments'),
    __metadata("design:paramtypes", [shipment_service_1.ShipmentService])
], ShipmentController);
//# sourceMappingURL=shipment.controller.js.map