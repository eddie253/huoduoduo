import { CurrencyItemDto, CurrencyListResponseDto } from './modules/currency/dto/currency-response.dto';
import { ProxyMateItemDto, ProxyKpiItemDto, ProxyMateListResponseDto, ProxyKpiListResponseDto } from './modules/proxy/dto/proxy-response.dto';
import { ReservationSupportItemDto, ReservationSupportListResponseDto } from './modules/reservation/dto/reservation-support-response.dto';
import { SystemVersionResponseDto } from './modules/system/dto/system-version-response.dto';
import type { UserProfileDto, WebviewBootstrapDto, LoginResponseDto, RefreshResponseDto, LogoutResponseDto } from './modules/auth/dto/auth-response.dto';
import type { ReservationResponseDto } from './modules/reservation/dto/reservation-response.dto';
import type { ShipmentResponseDto } from './modules/shipment/dto/shipment-response.dto';

describe('DTO construction coverage', () => {
  describe('CurrencyItemDto', () => {
    it('accepts all fields including nullables', () => {
      const dto = new CurrencyItemDto();
      dto.code = 'C001';
      dto.name = 'Daily';
      dto.status = 'ok';
      dto.service = 'currency';
      dto.role = null;
      dto.message = null;
      dto.currency = 'TWD';
      dto.orderNo = null;
      dto.address = null;
      dto.date = '2026-03-04';
      dto.amount = 100;
      dto.balance = 1000;
      expect(dto.code).toBe('C001');
      expect(dto.amount).toBe(100);
      expect(dto.role).toBeNull();
    });
  });

  describe('CurrencyListResponseDto', () => {
    it('holds an items array', () => {
      const item = new CurrencyItemDto();
      item.code = 'C002'; item.name = 'M'; item.status = null; item.service = null;
      item.role = null; item.message = null; item.currency = null; item.orderNo = null;
      item.address = null; item.date = null; item.amount = null; item.balance = null;
      const dto = new CurrencyListResponseDto();
      dto.items = [item];
      expect(dto.items).toHaveLength(1);
      expect(dto.items[0].code).toBe('C002');
    });
  });

  describe('ProxyMateItemDto', () => {
    it('accepts nullable area, status, service, role, message', () => {
      const dto = new ProxyMateItemDto();
      dto.code = 'P001'; dto.name = 'Mate';
      dto.area = null; dto.status = 'active'; dto.service = null;
      dto.role = null; dto.message = null; dto.updatedAt = '2026-03-01';
      expect(dto.code).toBe('P001');
      expect(dto.area).toBeNull();
    });
  });

  describe('ProxyKpiItemDto', () => {
    it('accepts nullable fields', () => {
      const dto = new ProxyKpiItemDto();
      dto.code = 'K001'; dto.name = 'KPI';
      dto.status = null; dto.service = null; dto.role = 'admin';
      dto.message = 'note'; dto.updatedAt = null;
      expect(dto.role).toBe('admin');
      expect(dto.updatedAt).toBeNull();
    });
  });

  describe('ProxyMateListResponseDto / ProxyKpiListResponseDto', () => {
    it('can hold empty items arrays', () => {
      const mate = new ProxyMateListResponseDto();
      mate.items = [];
      expect(mate.items).toEqual([]);

      const kpi = new ProxyKpiListResponseDto();
      kpi.items = [];
      expect(kpi.items).toEqual([]);
    });
  });

  describe('ReservationSupportItemDto', () => {
    it('accepts all nullable location fields', () => {
      const dto = new ReservationSupportItemDto();
      dto.code = 'R001'; dto.name = 'Support';
      dto.status = null; dto.service = null; dto.role = null; dto.message = null;
      dto.reservationNo = 'RES-1'; dto.trackingNo = 'T001';
      dto.zip = '100'; dto.areaCode = 'A01'; dto.address = 'Addr'; dto.date = '2026-03-04';
      expect(dto.reservationNo).toBe('RES-1');
      expect(dto.zip).toBe('100');
    });
  });

  describe('ReservationSupportListResponseDto', () => {
    it('holds empty items array', () => {
      const dto = new ReservationSupportListResponseDto();
      dto.items = [];
      expect(dto.items).toEqual([]);
    });
  });

  describe('SystemVersionResponseDto', () => {
    it('accepts name and numeric versionCode', () => {
      const dto = new SystemVersionResponseDto();
      dto.name = 'DriverAPP';
      dto.versionCode = 42;
      expect(dto.name).toBe('DriverAPP');
      expect(dto.versionCode).toBe(42);
    });
  });

  describe('Auth response interfaces (shape validation)', () => {
    it('LoginResponseDto shape is valid', () => {
      const dto: LoginResponseDto = {
        accessToken: 'at-1',
        refreshToken: 'rt-1',
        user: { id: 'D001', contractNo: 'C001', name: 'Driver', role: 'driver' },
        webviewBootstrap: {
          baseUrl: 'https://app.elf.com.tw',
          registerUrl: 'https://old.huoduoduo.com.tw/register',
          resetPasswordUrl: 'https://old.huoduoduo.com.tw/reset',
          cookies: []
        }
      };
      expect(dto.accessToken).toBe('at-1');
      expect(dto.user.role).toBe('driver');
    });

    it('RefreshResponseDto shape is valid', () => {
      const dto: RefreshResponseDto = { accessToken: 'at-2', refreshToken: 'rt-2' };
      expect(dto.refreshToken).toBe('rt-2');
    });

    it('LogoutResponseDto shape is valid', () => {
      const dto: LogoutResponseDto = { revoked: true, subject: 'D001' };
      expect(dto.revoked).toBe(true);
      expect(dto.subject).toBe('D001');
    });

    it('UserProfileDto shape is valid', () => {
      const dto: UserProfileDto = { id: 'D001', contractNo: 'C001', name: 'Test', role: 'driver' };
      expect(dto.contractNo).toBe('C001');
    });

    it('WebviewBootstrapDto shape is valid', () => {
      const dto: WebviewBootstrapDto = {
        baseUrl: 'https://app.elf.com.tw',
        registerUrl: 'https://r.example.com',
        resetPasswordUrl: 'https://p.example.com',
        cookies: [{ name: 'Account', value: 'A1', domain: 'example.com', path: '/', secure: true, httpOnly: false }]
      };
      expect(dto.cookies).toHaveLength(1);
    });
  });

  describe('Reservation and Shipment interfaces (shape validation)', () => {
    it('ReservationResponseDto standard mode', () => {
      const dto: ReservationResponseDto = {
        reservationNo: 'R001', address: 'Addr', fee: 120,
        shipmentNos: ['T001'], mode: 'standard'
      };
      expect(dto.mode).toBe('standard');
      expect(dto.fee).toBe(120);
    });

    it('ReservationResponseDto bulk mode with null fee', () => {
      const dto: ReservationResponseDto = {
        reservationNo: 'R002', address: 'Addr2', fee: null,
        shipmentNos: ['T002', 'T003'], mode: 'bulk'
      };
      expect(dto.mode).toBe('bulk');
      expect(dto.fee).toBeNull();
    });

    it('ShipmentResponseDto shape is valid', () => {
      const dto: ShipmentResponseDto = {
        trackingNo: 'T001', recipient: 'Alice', address: 'Addr',
        phone: '02-1234', mobile: '0912-345', zipCode: '100',
        city: 'Taipei', district: 'Zhongzheng', status: 'delivered',
        signedAt: '2026-03-04T10:00:00Z', signedImageFileName: 'img.jpg',
        signedLocation: '25.0,121.5'
      };
      expect(dto.trackingNo).toBe('T001');
      expect(dto.signedAt).not.toBeNull();
    });

    it('ShipmentResponseDto nullable signed fields', () => {
      const dto: ShipmentResponseDto = {
        trackingNo: 'T002', recipient: 'Bob', address: 'Addr2',
        phone: '', mobile: '', zipCode: '', city: '', district: '',
        status: 'pending', signedAt: null, signedImageFileName: null, signedLocation: null
      };
      expect(dto.signedAt).toBeNull();
      expect(dto.signedImageFileName).toBeNull();
    });
  });
});
