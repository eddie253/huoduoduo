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
exports.NoStoreResponseInterceptor = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const no_store_response_decorator_1 = require("./no-store-response.decorator");
let NoStoreResponseInterceptor = class NoStoreResponseInterceptor {
    constructor(reflector) {
        this.reflector = reflector;
    }
    intercept(context, next) {
        const enabled = this.reflector.getAllAndOverride(no_store_response_decorator_1.NO_STORE_RESPONSE_METADATA_KEY, [context.getHandler(), context.getClass()]);
        if (enabled) {
            const response = context.switchToHttp().getResponse();
            response.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
            response.setHeader('Pragma', 'no-cache');
            response.setHeader('Expires', '0');
        }
        return next.handle();
    }
};
exports.NoStoreResponseInterceptor = NoStoreResponseInterceptor;
exports.NoStoreResponseInterceptor = NoStoreResponseInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [core_1.Reflector])
], NoStoreResponseInterceptor);
//# sourceMappingURL=no-store-response.interceptor.js.map