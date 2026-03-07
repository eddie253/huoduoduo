import { ConfigService } from '@nestjs/config';
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
export declare class LegacySoapClient {
    private readonly transport;
    private readonly configService;
    constructor(transport: SoapTransportService, configService: ConfigService);
    validateLogin(account: string, password: string): Promise<LegacyUser | null>;
    buildWebviewCookies(account: string, identify: string): Promise<WebCookieModel[]>;
    getBulletins(): Promise<BulletinRecord[]>;
    private safeReadHost;
    updateRegId(contractNo: string, regId: string, kind?: 'Android' | 'android' | 'ios', version?: number): Promise<void>;
    deleteRegId(contractNo: string, regId: string): Promise<void>;
    getVersion(name: string): Promise<string>;
    getShipment(trackingNo: string): Promise<ShipmentRecord>;
    acceptOrder(contractNo: string, trackingNo: string): Promise<void>;
    uploadSignature(trackingNo: string, payload: {
        contractNo: string;
        signatureBase64: string;
    }): Promise<void>;
    reportDriverLocation(payload: {
        trackingNo: string;
        lat: string;
        lng: string;
        accuracyMeters?: string;
        recordedAt: string;
    }): Promise<void>;
    submitShipmentDelivery(trackingNo: string, payload: {
        contractNo: string;
        imageBase64: string;
        imageFileName: string;
        latitude: string;
        longitude: string;
    }): Promise<void>;
    submitShipmentException(trackingNo: string, payload: {
        contractNo: string;
        imageBase64: string;
        imageFileName: string;
        latitude: string;
        longitude: string;
    }): Promise<void>;
    listReservations(mode: ReservationMode, contractNo: string): Promise<ReservationRecord[]>;
    createReservation(mode: ReservationMode, payload: {
        contractNo: string;
        address: string;
        shipmentNos: string[];
        fee?: number;
    }): Promise<{
        reservationNo: string;
        mode: ReservationMode;
    }>;
    deleteReservation(mode: ReservationMode, id: string, address: string, contractNo: string): Promise<void>;
    getReservationZipAreas(): Promise<ReservationSupportRecord[]>;
    getReservationAvailable(zip: string, contractNo: string): Promise<ReservationSupportRecord[]>;
    getReservationAvailableBulk(zip: string, contractNo: string): Promise<ReservationSupportRecord[]>;
    getReservationAreaCodes(contractNo: string): Promise<ReservationSupportRecord[]>;
    getReservationArrived(contractNo: string): Promise<ReservationSupportRecord[]>;
    getProxyMates(area: string): Promise<ProxyMateRecord[]>;
    searchProxyKpi(year: string, month: string, area: string): Promise<ProxyKpiRecord[]>;
    getProxyKpi(year: string, month: string, area: string): Promise<ProxyKpiRecord[]>;
    getProxyKpiDaily(date: string, area: string): Promise<ProxyKpiRecord[]>;
    getDriverCurrency(date: string, contractNo: string): Promise<CurrencyRecord[]>;
    getDriverCurrencyMonth(date: string, contractNo: string): Promise<CurrencyRecord[]>;
    getDriverBalance(contractNo: string): Promise<CurrencyRecord[]>;
    getDepositHead(startDate: string, endDate: string, contractNo: string): Promise<CurrencyRecord[]>;
    getDepositBody(tnum: string, address: string, contractNo: string): Promise<CurrencyRecord[]>;
    getShipmentCurrency(orderNum: string): Promise<CurrencyRecord[]>;
    private normalizeShipment;
    private normalizeReservation;
    private normalizeBulletin;
    private normalizeReservationSupport;
    private normalizeProxyMate;
    private normalizeProxyKpi;
    private normalizeCurrency;
    private throwIfBusinessError;
    private isBusinessError;
    private parseJsonArray;
    private pickString;
    private pickNumber;
    private collectScalarValues;
}
