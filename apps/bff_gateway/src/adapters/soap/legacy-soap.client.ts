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
}
