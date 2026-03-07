import { Module } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { SoapModule } from './adapters/soap/soap.module';
import { readPositiveInt } from './core/config/number-env';
import { AuthModule } from './modules/auth/auth.module';
import { CurrencyModule } from './modules/currency/currency.module';
import { DriverLocationModule } from './modules/driver-location/driver-location.module';
import { HealthModule } from './modules/health/health.module';
import { NotificationModule } from './modules/notification/notification.module';
import { OrdersModule } from './modules/orders/orders.module';
import { ProxyModule } from './modules/proxy/proxy.module';
import { ReservationModule } from './modules/reservation/reservation.module';
import { ShipmentModule } from './modules/shipment/shipment.module';
import { SystemModule } from './modules/system/system.module';
import { WebviewModule } from './modules/webview/webview.module';
import { HttpLoggingInterceptor } from './observability/http-logging.interceptor';
import { BearerAuthGuard } from './security/bearer-auth.guard';
import { NoStoreResponseInterceptor } from './security/no-store-response.interceptor';
import { SecurityModule } from './security/security.module';
import { IdempotencyModule } from './shared/idempotency/idempotency.module';

@Module({
  imports: [
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, 'public'),
      serveRoot: '/static'
    }),
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const accessTokenTtl = readPositiveInt(
          config.get('ACCESS_TOKEN_TTL_SECONDS'),
          900,
          'ACCESS_TOKEN_TTL_SECONDS'
        );
        return {
          secret: config.get<string>('JWT_SECRET', 'dev-only-secret-change-me'),
          signOptions: {
            expiresIn: `${accessTokenTtl}s`
          }
        };
      }
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100
      }
    ]),
    SoapModule,
    SecurityModule,
    IdempotencyModule,
    HealthModule,
    AuthModule,
    WebviewModule,
    CurrencyModule,
    ShipmentModule,
    OrdersModule,
    DriverLocationModule,
    ReservationModule,
    NotificationModule,
    ProxyModule,
    SystemModule
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard
    },
    {
      provide: APP_GUARD,
      useClass: BearerAuthGuard
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: HttpLoggingInterceptor
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: NoStoreResponseInterceptor
    }
  ]
})
export class AppModule {}
