import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LegacySoapError } from './legacy-soap.error';
import { SoapTransportService } from './soap-transport.service';

export interface LegacyUser {
  id: string;
  account: string;
  displayName: string;
  role: string;
  contractNo: string;
}

export interface WebCookieModel {
  name: string;
  value: string;
  domain: string;
  path: string;
  secure: boolean;
  httpOnly: boolean;
}

export type ReservationMode = 'standard' | 'bulk';

export interface ShipmentRecord {
  trackingNo: string;
  recipient: string;
  address: string;
  phone: string;
  mobile: string;
  zipCode: string;
  city: string;
  district: string;
  status: string;
  signedAt: string | null;
  signedImageFileName: string | null;
  signedLocation: string | null;
}

export interface ReservationRecord {
  reservationNo: string;
  address: string;
  fee: number | null;
  shipmentNos: string[];
  mode: ReservationMode;
}

export interface BulletinRecord {
  uid: string;
  title: string;
  date: string | null;
}

export interface ProxyMateRecord {
  code: string;
  name: string;
  area: string | null;
  status: string | null;
  service: string | null;
  role: string | null;
  message: string | null;
  updatedAt: string | null;
}

export interface ProxyKpiRecord {
  code: string;
  name: string;
  status: string | null;
  service: string | null;
  role: string | null;
  message: string | null;
  updatedAt: string | null;
}

export interface CurrencyRecord {
  code: string;
  name: string;
  status: string | null;
  service: string | null;
  role: string | null;
  message: string | null;
  currency: string | null;
  orderNo: string | null;
  address: string | null;
  date: string | null;
  amount: number | null;
  balance: number | null;
}

export interface ReservationSupportRecord {
  code: string;
  name: string;
  status: string | null;
  service: string | null;
  role: string | null;
  message: string | null;
  reservationNo: string | null;
  trackingNo: string | null;
  zip: string | null;
  areaCode: string | null;
  address: string | null;
  date: string | null;
}

@Injectable()
export class LegacySoapClient {
  constructor(
    private readonly transport: SoapTransportService,
    private readonly configService: ConfigService
  ) {}

  async validateLogin(account: string, password: string): Promise<LegacyUser | null> {
    const raw = await this.transport.call({
      method: 'GetLogin',
      params: {
        Account: account,
        Password: password,
        Kind: 'android'
      }
    });
    this.throwIfBusinessError(raw, 'GetLogin');

    const rows = this.parseJsonArray(raw);
    if (rows.length === 0) {
      return null;
    }
    const row = rows[0];

    const contractNo = this.pickString(row, ['契約編號', 'DNUM']);
    if (!contractNo) {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'GetLogin payload missing contract number.');
    }

    return {
      id: contractNo,
      contractNo,
      account,
      displayName: this.pickString(row, ['姓名', 'Name']) || account,
      role: this.pickString(row, ['代理區域職位', 'Role']) || 'driver'
    };
  }

  async buildWebviewCookies(account: string, identify: string): Promise<WebCookieModel[]> {
    const configuredDomain = this.configService.get<string>('WEBVIEW_COOKIE_DOMAIN');
    const baseUrl = this.configService.get<string>(
      'WEBVIEW_BASE_URL',
      'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1'
    );
    const baseUrlHost = this.safeReadHost(baseUrl);
    const defaultDomain = configuredDomain || baseUrlHost || 'old.huoduoduo.com.tw';
    return [
      {
        name: 'Account',
        value: account,
        domain: defaultDomain,
        path: '/',
        secure: true,
        httpOnly: false
      },
      {
        name: 'Identify',
        value: identify,
        domain: defaultDomain,
        path: '/',
        secure: true,
        httpOnly: false
      },
      {
        name: 'Kind',
        value: 'android',
        domain: defaultDomain,
        path: '/',
        secure: true,
        httpOnly: false
      }
    ];
  }

  async getBulletins(): Promise<BulletinRecord[]> {
    const raw = await this.transport.call({
      method: 'GetBulletin'
    });
    this.throwIfBusinessError(raw, 'GetBulletin');

    const rows = this.parseJsonArray(raw);
    const mapped = rows
      .map((item) => this.normalizeBulletin(item))
      .filter((item): item is BulletinRecord => item != null);

    return mapped;
  }

  private safeReadHost(url: string): string | null {
    try {
      const parsed = new URL(url);
      return parsed.host || null;
    } catch {
      return null;
    }
  }

  async updateRegId(
    contractNo: string,
    regId: string,
    kind: 'Android' | 'android' | 'ios' = 'Android',
    version = 0
  ): Promise<void> {
    const raw = await this.transport.call({
      method: 'UpdateRegID',
      params: {
        DNUM: contractNo,
        RegID: regId,
        Kind: kind,
        Version: String(version)
      }
    });
    this.throwIfBusinessError(raw, 'UpdateRegID');
  }

  async deleteRegId(contractNo: string, regId: string): Promise<void> {
    const raw = await this.transport.call({
      method: 'DeleteRegID',
      params: {
        Contract: contractNo,
        RegID: regId
      }
    });
    this.throwIfBusinessError(raw, 'DeleteRegID');
  }

  async getVersion(name: string): Promise<string> {
    const raw = await this.transport.call({
      method: 'GetVersion',
      params: {
        Name: name
      }
    });
    this.throwIfBusinessError(raw, 'GetVersion');
    return raw.trim();
  }

  async getShipment(trackingNo: string): Promise<ShipmentRecord> {
    let raw = await this.transport.call({
      method: 'GetShipment_elf',
      params: {
        TNUM: trackingNo
      }
    });

    if (this.isBusinessError(raw)) {
      throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, `GetShipment_elf failed: ${raw}`);
    }

    let rows = this.parseJsonArray(raw);
    if (rows.length === 0) {
      raw = await this.transport.call({
        method: 'GetShipment',
        params: {
          TNUM: trackingNo
        }
      });
      this.throwIfBusinessError(raw, 'GetShipment');
      rows = this.parseJsonArray(raw);
    }

    if (rows.length === 0) {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'Shipment not found in legacy response.');
    }

    return this.normalizeShipment(rows[0], trackingNo);
  }

  async acceptOrder(contractNo: string, trackingNo: string): Promise<void> {
    const method = 'AddOrder_elf';
    const raw = await this.transport.call({
      method,
      params: {
        DNUM: contractNo,
        TNUM: trackingNo
      }
    });
    this.throwIfBusinessError(raw, method);
  }

  async submitShipmentDelivery(
    trackingNo: string,
    payload: {
      contractNo: string;
      imageBase64: string;
      imageFileName: string;
      latitude: string;
      longitude: string;
    }
  ): Promise<void> {
    const raw = await this.transport.call({
      method: 'UpdateArrival',
      params: {
        DNUM: payload.contractNo,
        TNUM: trackingNo,
        Image: payload.imageBase64,
        Image_FN: payload.imageFileName,
        Itude: `${payload.latitude},${payload.longitude}`
      }
    });
    this.throwIfBusinessError(raw, 'UpdateArrival');
  }

  async submitShipmentException(
    trackingNo: string,
    payload: {
      contractNo: string;
      imageBase64: string;
      imageFileName: string;
      latitude: string;
      longitude: string;
    }
  ): Promise<void> {
    const raw = await this.transport.call({
      method: 'UpdateArrivalErr_NEW',
      params: {
        DNUM: payload.contractNo,
        TNUM: trackingNo,
        Image: payload.imageBase64,
        Image_FN: payload.imageFileName,
        Itude: `${payload.latitude},${payload.longitude}`
      }
    });
    this.throwIfBusinessError(raw, 'UpdateArrivalErr_NEW');
  }

  async listReservations(mode: ReservationMode, contractNo: string): Promise<ReservationRecord[]> {
    const method = mode === 'bulk' ? 'GetBARVed' : 'GetARVed';
    const raw = await this.transport.call({
      method,
      params: {
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeReservation(item, mode));
  }

  async createReservation(
    mode: ReservationMode,
    payload: {
      contractNo: string;
      address: string;
      shipmentNos: string[];
      fee?: number;
    }
  ): Promise<{ reservationNo: string; mode: ReservationMode }> {
    const method = mode === 'bulk' ? 'UpdateBARV' : 'UpdateARV';
    const trackingNo = payload.shipmentNos.join(',');
    const raw = await this.transport.call({
      method,
      params:
        mode === 'bulk'
          ? {
              NUM: payload.shipmentNos[0] ?? '',
              Addr: payload.address,
              FEE: String(payload.fee ?? 0),
              DNUM: payload.contractNo
            }
          : {
              NUMs: trackingNo,
              Addr: payload.address,
              DNUM: payload.contractNo
            }
    });
    this.throwIfBusinessError(raw, method);
    return {
      reservationNo: payload.shipmentNos[0] ?? trackingNo,
      mode
    };
  }

  async deleteReservation(
    mode: ReservationMode,
    id: string,
    address: string,
    contractNo: string
  ): Promise<void> {
    const method = mode === 'bulk' ? 'RemoveBARV' : 'RemoveARV';
    const raw = await this.transport.call({
      method,
      params:
        mode === 'bulk'
          ? {
              NUM: id,
              Addr: address,
              DNUM: contractNo
            }
          : {
              NUMs: id,
              Addr: address,
              DNUM: contractNo
            }
    });
    this.throwIfBusinessError(raw, method);
  }

  async getReservationZipAreas(): Promise<ReservationSupportRecord[]> {
    const method = 'GetARV_ZIP';
    const raw = await this.transport.call({
      method
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeReservationSupport(item));
  }

  async getReservationAvailable(zip: string, contractNo: string): Promise<ReservationSupportRecord[]> {
    const method = 'GetARV';
    const raw = await this.transport.call({
      method,
      params: {
        ZIP: zip,
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeReservationSupport(item));
  }

  async getReservationAvailableBulk(zip: string, contractNo: string): Promise<ReservationSupportRecord[]> {
    const method = 'GetBARV';
    const raw = await this.transport.call({
      method,
      params: {
        ZIP: zip,
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeReservationSupport(item));
  }

  async getReservationAreaCodes(contractNo: string): Promise<ReservationSupportRecord[]> {
    const method = 'GetAreaCode';
    const raw = await this.transport.call({
      method,
      params: {
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeReservationSupport(item));
  }

  async getReservationArrived(contractNo: string): Promise<ReservationSupportRecord[]> {
    const method = 'GetArrived';
    const raw = await this.transport.call({
      method,
      params: {
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeReservationSupport(item));
  }

  async getProxyMates(area: string): Promise<ProxyMateRecord[]> {
    const method = 'GetPxymate';
    const raw = await this.transport.call({
      method,
      params: {
        Area: area
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeProxyMate(item));
  }

  async searchProxyKpi(year: string, month: string, area: string): Promise<ProxyKpiRecord[]> {
    const method = 'SearchKPI';
    const raw = await this.transport.call({
      method,
      params: {
        Year: year,
        Month: month,
        Area: area
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeProxyKpi(item));
  }

  async getProxyKpi(year: string, month: string, area: string): Promise<ProxyKpiRecord[]> {
    const method = 'GetKPI';
    const raw = await this.transport.call({
      method,
      params: {
        Year: year,
        Month: month,
        Area: area
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeProxyKpi(item));
  }

  async getProxyKpiDaily(date: string, area: string): Promise<ProxyKpiRecord[]> {
    const method = 'GetKPI_dis';
    const raw = await this.transport.call({
      method,
      params: {
        DD: date,
        Area: area
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeProxyKpi(item));
  }

  async getDriverCurrency(date: string, contractNo: string): Promise<CurrencyRecord[]> {
    const method = 'GetDriverCurrency';
    const raw = await this.transport.call({
      method,
      params: {
        DD: date,
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeCurrency(item));
  }

  async getDriverCurrencyMonth(date: string, contractNo: string): Promise<CurrencyRecord[]> {
    const method = 'GetDriverCurrencyMonth';
    const raw = await this.transport.call({
      method,
      params: {
        DD: date,
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeCurrency(item));
  }

  async getDriverBalance(contractNo: string): Promise<CurrencyRecord[]> {
    const method = 'GetDriverBalance';
    const raw = await this.transport.call({
      method,
      params: {
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeCurrency(item));
  }

  async getDepositHead(startDate: string, endDate: string, contractNo: string): Promise<CurrencyRecord[]> {
    const method = 'GetDeposit_Head';
    const raw = await this.transport.call({
      method,
      params: {
        StartDate: startDate,
        EndDate: endDate,
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeCurrency(item));
  }

  async getDepositBody(tnum: string, address: string, contractNo: string): Promise<CurrencyRecord[]> {
    const method = 'GetDeposit_Body';
    const raw = await this.transport.call({
      method,
      params: {
        TNUM: tnum,
        Addr: address,
        DNUM: contractNo
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeCurrency(item));
  }

  async getShipmentCurrency(orderNum: string): Promise<CurrencyRecord[]> {
    const method = 'GetShipment_Currency';
    const raw = await this.transport.call({
      method,
      params: {
        OrderNum: orderNum
      }
    });
    this.throwIfBusinessError(raw, method);
    const rows = this.parseJsonArray(raw);
    return rows.map((item) => this.normalizeCurrency(item));
  }

  private normalizeShipment(input: Record<string, unknown>, fallbackTrackingNo: string): ShipmentRecord {
    return {
      trackingNo: this.pickString(input, ['查件貨號', 'TNUM']) || fallbackTrackingNo,
      recipient: this.pickString(input, ['收件人']) || '',
      address: this.pickString(input, ['地址']) || '',
      phone: this.pickString(input, ['電話']) || '',
      mobile: this.pickString(input, ['手機']) || '',
      zipCode: this.pickString(input, ['郵遞區號']) || '',
      city: this.pickString(input, ['縣市']) || '',
      district: this.pickString(input, ['地區']) || '',
      status: this.pickString(input, ['配送狀態']) || '',
      signedAt: this.pickString(input, ['送達時間']) || null,
      signedImageFileName: this.pickString(input, ['送達簽收檔名']) || null,
      signedLocation: this.pickString(input, ['簽收經緯度']) || null
    };
  }

  private normalizeReservation(
    input: Record<string, unknown>,
    mode: ReservationMode
  ): ReservationRecord {
    const shipmentNosRaw = this.pickString(input, ['提單號碼s', '提單號碼', 'NUMs', 'NUM']) || '';
    const shipmentNos = shipmentNosRaw
      .split(',')
      .map((it) => it.trim())
      .filter((it) => it.length > 0);

    return {
      reservationNo:
        this.pickString(input, ['提單號碼', 'NUM', 'NUMs', '查件貨號']) ||
        shipmentNos[0] ||
        'unknown',
      address: this.pickString(input, ['地址', 'Addr']) || '',
      fee: this.pickNumber(input, ['運費', 'FEE']),
      shipmentNos,
      mode
    };
  }

  private normalizeBulletin(input: Record<string, unknown>): BulletinRecord | null {
    const title =
      this.pickString(input, [
        '\u516C\u544A\u6A19\u984C',
        '\u516C\u544A\u6A19\u9898',
        'title',
        'Title',
        'BulletinTitle'
      ]) ?? '';

    if (title.trim().length === 0) {
      return null;
    }

    return {
      uid:
        this.pickString(input, ['UID', '\u516C\u544AUID', 'Id', 'id']) ??
        '0',
      title,
      date: this.pickString(input, [
        '\u516C\u544A\u65E5\u671F',
        '\u65E5\u671F',
        'Date',
        'CreateTime'
      ])
    };
  }

  private normalizeReservationSupport(input: Record<string, unknown>): ReservationSupportRecord {
    const values = this.collectScalarValues(input);
    const code =
      this.pickString(input, ['Code', 'code', 'ID', 'Id', 'uid', 'ZIP', 'AreaCode']) ||
      values[0] ||
      'UNKNOWN';
    const name = this.pickString(input, ['Name', 'name', 'Title', 'title']) || values[1] || code;

    return {
      code,
      name,
      status: this.pickString(input, ['Status', 'status']),
      service: this.pickString(input, ['Service', 'service']),
      role: this.pickString(input, ['Role', 'role']),
      message: this.pickString(input, ['Message', 'message', 'Note', 'note']),
      reservationNo: this.pickString(input, ['NUM', 'NUMs', 'ReservationNo', 'reservationNo']),
      trackingNo: this.pickString(input, ['TNUM', 'TrackingNo', 'trackingNo']),
      zip: this.pickString(input, ['ZIP', 'Zip', 'zip']),
      areaCode: this.pickString(input, ['AreaCode', 'areaCode']),
      address: this.pickString(input, ['Addr', 'address', 'Address']),
      date: this.pickString(input, ['Date', 'date', 'DD', 'UpdateTime', 'updatedAt'])
    };
  }

  private normalizeProxyMate(input: Record<string, unknown>): ProxyMateRecord {
    const values = this.collectScalarValues(input);
    const code = this.pickString(input, ['Code', 'code', 'ID', 'Id', 'uid']) || values[0] || 'UNKNOWN';
    const name = this.pickString(input, ['Name', 'name', 'Title', 'title']) || values[1] || code;

    return {
      code,
      name,
      area: this.pickString(input, ['Area', 'area', 'Region', 'region']),
      status: this.pickString(input, ['Status', 'status']),
      service: this.pickString(input, ['Service', 'service']),
      role: this.pickString(input, ['Role', 'role']),
      message: this.pickString(input, ['Message', 'message', 'Note', 'note']),
      updatedAt: this.pickString(input, ['Date', 'date', 'UpdateTime', 'updatedAt', 'DD'])
    };
  }

  private normalizeProxyKpi(input: Record<string, unknown>): ProxyKpiRecord {
    const values = this.collectScalarValues(input);
    const code = this.pickString(input, ['Code', 'code', 'ID', 'Id', 'uid']) || values[0] || 'UNKNOWN';
    const name = this.pickString(input, ['Name', 'name', 'Title', 'title']) || values[1] || code;

    return {
      code,
      name,
      status: this.pickString(input, ['Status', 'status']),
      service: this.pickString(input, ['Service', 'service']),
      role: this.pickString(input, ['Role', 'role']),
      message: this.pickString(input, ['Message', 'message', 'Note', 'note']),
      updatedAt: this.pickString(input, ['Date', 'date', 'UpdateTime', 'updatedAt', 'DD'])
    };
  }

  private normalizeCurrency(input: Record<string, unknown>): CurrencyRecord {
    const values = this.collectScalarValues(input);
    const code = this.pickString(input, ['Code', 'code', 'ID', 'Id', 'uid']) || values[0] || 'UNKNOWN';
    const name = this.pickString(input, ['Name', 'name', 'Title', 'title']) || values[1] || code;

    return {
      code,
      name,
      status: this.pickString(input, ['Status', 'status']),
      service: this.pickString(input, ['Service', 'service']),
      role: this.pickString(input, ['Role', 'role']),
      message: this.pickString(input, ['Message', 'message', 'Note', 'note']),
      currency: this.pickString(input, ['Currency', 'currency', 'CY']),
      orderNo: this.pickString(input, ['OrderNum', 'orderNum', 'TNUM']),
      address: this.pickString(input, ['Addr', 'address']),
      date: this.pickString(input, ['Date', 'date', 'DD', 'StartDate', 'EndDate']),
      amount: this.pickNumber(input, ['Amount', 'amount', 'Money', 'money', 'FEE']),
      balance: this.pickNumber(input, ['Balance', 'balance', 'Total', 'total', 'Money', 'money'])
    };
  }

  private throwIfBusinessError(raw: string, method: string): void {
    if (this.isBusinessError(raw)) {
      throw new LegacySoapError('LEGACY_BUSINESS_ERROR', 422, `${method} failed: ${raw}`);
    }
  }

  private isBusinessError(raw: string): boolean {
    return raw.trim().startsWith('Error');
  }

  private parseJsonArray(raw: string): Record<string, unknown>[] {
    const trimmed = raw.trim();
    if (!trimmed || trimmed === 'null') {
      return [];
    }
    try {
      const parsed = JSON.parse(trimmed) as unknown;
      if (Array.isArray(parsed)) {
        return parsed.filter((it): it is Record<string, unknown> => !!it && typeof it === 'object');
      }
      if (parsed && typeof parsed === 'object') {
        return [parsed as Record<string, unknown>];
      }
      return [];
    } catch {
      throw new LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'Legacy payload is not valid JSON.');
    }
  }

  private pickString(
    input: Record<string, unknown>,
    keys: string[]
  ): string | null {
    for (const key of keys) {
      const value = input[key];
      if (typeof value === 'string' && value.trim().length > 0) {
        return value;
      }
      if (typeof value === 'number' || typeof value === 'boolean') {
        return String(value);
      }
    }
    return null;
  }

  private pickNumber(
    input: Record<string, unknown>,
    keys: string[]
  ): number | null {
    for (const key of keys) {
      const value = input[key];
      if (typeof value === 'number') {
        return value;
      }
      if (typeof value === 'string' && value.trim().length > 0) {
        const n = Number(value);
        if (!Number.isNaN(n)) {
          return n;
        }
      }
    }
    return null;
  }

  private collectScalarValues(input: Record<string, unknown>): string[] {
    return Object.values(input).flatMap((value) => {
      if (typeof value === 'string' && value.trim().length > 0) {
        return [value];
      }
      if (typeof value === 'number' || typeof value === 'boolean') {
        return [String(value)];
      }
      return [];
    });
  }
}
