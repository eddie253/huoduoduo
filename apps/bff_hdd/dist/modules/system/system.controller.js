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
exports.SystemController = void 0;
const common_1 = require("@nestjs/common");
const no_store_response_decorator_1 = require("../../security/no-store-response.decorator");
const public_decorator_1 = require("../../security/public.decorator");
const system_version_query_dto_1 = require("./dto/system-version-query.dto");
const system_service_1 = require("./system.service");
let SystemController = class SystemController {
    constructor(systemService) {
        this.systemService = systemService;
    }
    getVersion(query) {
        return this.systemService.getVersion(query.name);
    }
};
exports.SystemController = SystemController;
__decorate([
    (0, public_decorator_1.Public)(),
    (0, common_1.Get)('version'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [system_version_query_dto_1.SystemVersionQueryDto]),
    __metadata("design:returntype", Promise)
], SystemController.prototype, "getVersion", null);
exports.SystemController = SystemController = __decorate([
    (0, no_store_response_decorator_1.NoStoreResponse)(),
    (0, common_1.Controller)('system'),
    __metadata("design:paramtypes", [system_service_1.SystemService])
], SystemController);
//# sourceMappingURL=system.controller.js.map