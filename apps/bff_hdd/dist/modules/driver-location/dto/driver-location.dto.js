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
exports.DriverLocationDto = void 0;
const class_validator_1 = require("class-validator");
class DriverLocationDto {
}
exports.DriverLocationDto = DriverLocationDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(64),
    __metadata("design:type", String)
], DriverLocationDto.prototype, "trackingNo", void 0);
__decorate([
    (0, class_validator_1.IsNumberString)(),
    (0, class_validator_1.MaxLength)(32),
    __metadata("design:type", String)
], DriverLocationDto.prototype, "lat", void 0);
__decorate([
    (0, class_validator_1.IsNumberString)(),
    (0, class_validator_1.MaxLength)(32),
    __metadata("design:type", String)
], DriverLocationDto.prototype, "lng", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumberString)(),
    (0, class_validator_1.MaxLength)(16),
    __metadata("design:type", String)
], DriverLocationDto.prototype, "accuracyMeters", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(32),
    __metadata("design:type", String)
], DriverLocationDto.prototype, "recordedAt", void 0);
//# sourceMappingURL=driver-location.dto.js.map