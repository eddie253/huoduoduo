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
exports.CurrencyShipmentQueryDto = exports.CurrencyDepositBodyQueryDto = exports.CurrencyDepositHeadQueryDto = exports.CurrencyDateQueryDto = void 0;
const class_validator_1 = require("class-validator");
class CurrencyDateQueryDto {
}
exports.CurrencyDateQueryDto = CurrencyDateQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(40),
    __metadata("design:type", String)
], CurrencyDateQueryDto.prototype, "date", void 0);
class CurrencyDepositHeadQueryDto {
}
exports.CurrencyDepositHeadQueryDto = CurrencyDepositHeadQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(40),
    __metadata("design:type", String)
], CurrencyDepositHeadQueryDto.prototype, "startDate", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(40),
    __metadata("design:type", String)
], CurrencyDepositHeadQueryDto.prototype, "endDate", void 0);
class CurrencyDepositBodyQueryDto {
}
exports.CurrencyDepositBodyQueryDto = CurrencyDepositBodyQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(64),
    __metadata("design:type", String)
], CurrencyDepositBodyQueryDto.prototype, "tnum", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(512),
    __metadata("design:type", String)
], CurrencyDepositBodyQueryDto.prototype, "address", void 0);
class CurrencyShipmentQueryDto {
}
exports.CurrencyShipmentQueryDto = CurrencyShipmentQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(64),
    __metadata("design:type", String)
], CurrencyShipmentQueryDto.prototype, "orderNum", void 0);
//# sourceMappingURL=currency-query.dto.js.map