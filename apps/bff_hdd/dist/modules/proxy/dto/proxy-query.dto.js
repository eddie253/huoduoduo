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
exports.ProxyKpiDailyQueryDto = exports.ProxyKpiQueryDto = exports.ProxyAreaQueryDto = void 0;
const class_validator_1 = require("class-validator");
class ProxyAreaQueryDto {
}
exports.ProxyAreaQueryDto = ProxyAreaQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(64),
    __metadata("design:type", String)
], ProxyAreaQueryDto.prototype, "area", void 0);
class ProxyKpiQueryDto extends ProxyAreaQueryDto {
}
exports.ProxyKpiQueryDto = ProxyKpiQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(4),
    (0, class_validator_1.Matches)(/^\d{4}$/),
    __metadata("design:type", String)
], ProxyKpiQueryDto.prototype, "year", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(2),
    (0, class_validator_1.Matches)(/^\d{1,2}$/),
    __metadata("design:type", String)
], ProxyKpiQueryDto.prototype, "month", void 0);
class ProxyKpiDailyQueryDto extends ProxyAreaQueryDto {
}
exports.ProxyKpiDailyQueryDto = ProxyKpiDailyQueryDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.MaxLength)(10),
    (0, class_validator_1.Matches)(/^\d{4}-\d{2}-\d{2}$/),
    __metadata("design:type", String)
], ProxyKpiDailyQueryDto.prototype, "date", void 0);
//# sourceMappingURL=proxy-query.dto.js.map