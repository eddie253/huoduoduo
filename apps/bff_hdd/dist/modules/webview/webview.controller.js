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
exports.WebviewController = void 0;
const common_1 = require("@nestjs/common");
const no_store_response_decorator_1 = require("../../security/no-store-response.decorator");
const webview_service_1 = require("./webview.service");
let WebviewController = class WebviewController {
    constructor(webviewService) {
        this.webviewService = webviewService;
    }
    getWebviewBootstrap(request) {
        const claims = request.user;
        if (!claims) {
            throw new common_1.UnauthorizedException('Missing auth claims.');
        }
        return this.webviewService.getBootstrap(claims.account, claims.identify);
    }
    getCurrentBulletin(request) {
        const claims = request.user;
        if (!claims) {
            throw new common_1.UnauthorizedException('Missing auth claims.');
        }
        return this.webviewService.getCurrentBulletin();
    }
};
exports.WebviewController = WebviewController;
__decorate([
    (0, common_1.Get)('webview'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], WebviewController.prototype, "getWebviewBootstrap", null);
__decorate([
    (0, common_1.Get)('bulletin'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], WebviewController.prototype, "getCurrentBulletin", null);
exports.WebviewController = WebviewController = __decorate([
    (0, no_store_response_decorator_1.NoStoreResponse)(),
    (0, common_1.Controller)('bootstrap'),
    __metadata("design:paramtypes", [webview_service_1.WebviewService])
], WebviewController);
//# sourceMappingURL=webview.controller.js.map