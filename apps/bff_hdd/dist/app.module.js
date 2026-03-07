"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const config_1 = require("@nestjs/config");
const jwt_1 = require("@nestjs/jwt");
const throttler_1 = require("@nestjs/throttler");
const serve_static_1 = require("@nestjs/serve-static");
const path_1 = require("path");
const soap_module_1 = require("./adapters/soap/soap.module");
const number_env_1 = require("./core/config/number-env");
const auth_module_1 = require("./modules/auth/auth.module");
const currency_module_1 = require("./modules/currency/currency.module");
const driver_location_module_1 = require("./modules/driver-location/driver-location.module");
const health_module_1 = require("./modules/health/health.module");
const notification_module_1 = require("./modules/notification/notification.module");
const orders_module_1 = require("./modules/orders/orders.module");
const proxy_module_1 = require("./modules/proxy/proxy.module");
const reservation_module_1 = require("./modules/reservation/reservation.module");
const shipment_module_1 = require("./modules/shipment/shipment.module");
const system_module_1 = require("./modules/system/system.module");
const webview_module_1 = require("./modules/webview/webview.module");
const http_logging_interceptor_1 = require("./observability/http-logging.interceptor");
const bearer_auth_guard_1 = require("./security/bearer-auth.guard");
const no_store_response_interceptor_1 = require("./security/no-store-response.interceptor");
const security_module_1 = require("./security/security.module");
const idempotency_module_1 = require("./shared/idempotency/idempotency.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            serve_static_1.ServeStaticModule.forRoot({
                rootPath: (0, path_1.join)(__dirname, 'public'),
                serveRoot: '/static'
            }),
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            jwt_1.JwtModule.registerAsync({
                global: true,
                inject: [config_1.ConfigService],
                useFactory: (config) => {
                    const accessTokenTtl = (0, number_env_1.readPositiveInt)(config.get('ACCESS_TOKEN_TTL_SECONDS'), 900, 'ACCESS_TOKEN_TTL_SECONDS');
                    return {
                        secret: config.get('JWT_SECRET', 'dev-only-secret-change-me'),
                        signOptions: {
                            expiresIn: `${accessTokenTtl}s`
                        }
                    };
                }
            }),
            throttler_1.ThrottlerModule.forRoot([
                {
                    ttl: 60000,
                    limit: 100
                }
            ]),
            soap_module_1.SoapModule,
            security_module_1.SecurityModule,
            idempotency_module_1.IdempotencyModule,
            health_module_1.HealthModule,
            auth_module_1.AuthModule,
            webview_module_1.WebviewModule,
            currency_module_1.CurrencyModule,
            shipment_module_1.ShipmentModule,
            orders_module_1.OrdersModule,
            driver_location_module_1.DriverLocationModule,
            reservation_module_1.ReservationModule,
            notification_module_1.NotificationModule,
            proxy_module_1.ProxyModule,
            system_module_1.SystemModule
        ],
        providers: [
            {
                provide: core_1.APP_GUARD,
                useClass: throttler_1.ThrottlerGuard
            },
            {
                provide: core_1.APP_GUARD,
                useClass: bearer_auth_guard_1.BearerAuthGuard
            },
            {
                provide: core_1.APP_INTERCEPTOR,
                useClass: http_logging_interceptor_1.HttpLoggingInterceptor
            },
            {
                provide: core_1.APP_INTERCEPTOR,
                useClass: no_store_response_interceptor_1.NoStoreResponseInterceptor
            }
        ]
    })
], AppModule);
//# sourceMappingURL=app.module.js.map