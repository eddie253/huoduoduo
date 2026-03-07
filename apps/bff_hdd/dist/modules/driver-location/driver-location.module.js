"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DriverLocationModule = void 0;
const common_1 = require("@nestjs/common");
const driver_location_controller_1 = require("./driver-location.controller");
const driver_location_service_1 = require("./driver-location.service");
let DriverLocationModule = class DriverLocationModule {
};
exports.DriverLocationModule = DriverLocationModule;
exports.DriverLocationModule = DriverLocationModule = __decorate([
    (0, common_1.Module)({
        controllers: [driver_location_controller_1.DriverLocationController],
        providers: [driver_location_service_1.DriverLocationService]
    })
], DriverLocationModule);
//# sourceMappingURL=driver-location.module.js.map