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
exports.LegacySoapClient = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const legacy_soap_error_1 = require("./legacy-soap.error");
const soap_transport_service_1 = require("./soap-transport.service");
let LegacySoapClient = class LegacySoapClient {
    constructor(transport, configService) {
        this.transport = transport;
        this.configService = configService;
    }
    async validateLogin(account, password) {
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
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'GetLogin payload missing contract number.');
        }
        return {
            id: contractNo,
            contractNo,
            account,
            displayName: this.pickString(row, ['姓名', 'Name']) || account,
            role: this.pickString(row, ['代理區域職位', 'Role']) || 'driver'
        };
    }
    async buildWebviewCookies(account, identify) {
        const configuredDomain = this.configService.get('WEBVIEW_COOKIE_DOMAIN');
        const baseUrl = this.configService.get('WEBVIEW_BASE_URL', 'https://app.elf.com.tw/cn/entrust.aspx?IDCompany=S1');
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
    async getBulletins() {
        const raw = await this.transport.call({
            method: 'GetBulletin'
        });
        this.throwIfBusinessError(raw, 'GetBulletin');
        const rows = this.parseJsonArray(raw);
        const mapped = rows
            .map((item) => this.normalizeBulletin(item))
            .filter((item) => item != null);
        return mapped;
    }
    safeReadHost(url) {
        try {
            const parsed = new URL(url);
            return parsed.host || null;
        }
        catch {
            return null;
        }
    }
    async updateRegId(contractNo, regId, kind = 'Android', version = 0) {
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
    async deleteRegId(contractNo, regId) {
        const raw = await this.transport.call({
            method: 'DeleteRegID',
            params: {
                Contract: contractNo,
                RegID: regId
            }
        });
        this.throwIfBusinessError(raw, 'DeleteRegID');
    }
    async getVersion(name) {
        const raw = await this.transport.call({
            method: 'GetVersion',
            params: {
                Name: name
            }
        });
        this.throwIfBusinessError(raw, 'GetVersion');
        return raw.trim();
    }
    async getShipment(trackingNo) {
        let raw = await this.transport.call({
            method: 'GetShipment_elf',
            params: {
                TNUM: trackingNo
            }
        });
        if (this.isBusinessError(raw)) {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BUSINESS_ERROR', 422, `GetShipment_elf failed: ${raw}`);
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
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'Shipment not found in legacy response.');
        }
        return this.normalizeShipment(rows[0], trackingNo);
    }
    async acceptOrder(contractNo, trackingNo) {
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
    async uploadSignature(trackingNo, payload) {
        const raw = await this.transport.call({
            method: 'UploadSignature',
            params: {
                DNUM: payload.contractNo,
                TNUM: trackingNo,
                Image: payload.signatureBase64
            }
        });
        this.throwIfBusinessError(raw, 'UploadSignature');
    }
    async reportDriverLocation(payload) {
        const raw = await this.transport.call({
            method: 'ReportDriverLocation',
            params: {
                TNUM: payload.trackingNo,
                LAT: payload.lat,
                LNG: payload.lng,
                ACCURACY: payload.accuracyMeters ?? '',
                RECORDED_AT: payload.recordedAt
            }
        });
        this.throwIfBusinessError(raw, 'ReportDriverLocation');
    }
    async submitShipmentDelivery(trackingNo, payload) {
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
    async submitShipmentException(trackingNo, payload) {
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
    async listReservations(mode, contractNo) {
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
    async createReservation(mode, payload) {
        const method = mode === 'bulk' ? 'UpdateBARV' : 'UpdateARV';
        const trackingNo = payload.shipmentNos.join(',');
        const raw = await this.transport.call({
            method,
            params: mode === 'bulk'
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
    async deleteReservation(mode, id, address, contractNo) {
        const method = mode === 'bulk' ? 'RemoveBARV' : 'RemoveARV';
        const raw = await this.transport.call({
            method,
            params: mode === 'bulk'
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
    async getReservationZipAreas() {
        const method = 'GetARV_ZIP';
        const raw = await this.transport.call({
            method
        });
        this.throwIfBusinessError(raw, method);
        const rows = this.parseJsonArray(raw);
        return rows.map((item) => this.normalizeReservationSupport(item));
    }
    async getReservationAvailable(zip, contractNo) {
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
    async getReservationAvailableBulk(zip, contractNo) {
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
    async getReservationAreaCodes(contractNo) {
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
    async getReservationArrived(contractNo) {
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
    async getProxyMates(area) {
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
    async searchProxyKpi(year, month, area) {
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
    async getProxyKpi(year, month, area) {
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
    async getProxyKpiDaily(date, area) {
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
    async getDriverCurrency(date, contractNo) {
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
    async getDriverCurrencyMonth(date, contractNo) {
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
    async getDriverBalance(contractNo) {
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
    async getDepositHead(startDate, endDate, contractNo) {
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
    async getDepositBody(tnum, address, contractNo) {
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
    async getShipmentCurrency(orderNum) {
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
    normalizeShipment(input, fallbackTrackingNo) {
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
    normalizeReservation(input, mode) {
        const shipmentNosRaw = this.pickString(input, ['提單號碼s', '提單號碼', 'NUMs', 'NUM']) || '';
        const shipmentNos = shipmentNosRaw
            .split(',')
            .map((it) => it.trim())
            .filter((it) => it.length > 0);
        return {
            reservationNo: this.pickString(input, ['提單號碼', 'NUM', 'NUMs', '查件貨號']) ||
                shipmentNos[0] ||
                'unknown',
            address: this.pickString(input, ['地址', 'Addr']) || '',
            fee: this.pickNumber(input, ['運費', 'FEE']),
            shipmentNos,
            mode
        };
    }
    normalizeBulletin(input) {
        const title = this.pickString(input, [
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
            uid: this.pickString(input, ['UID', '\u516C\u544AUID', 'Id', 'id']) ??
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
    normalizeReservationSupport(input) {
        const values = this.collectScalarValues(input);
        const code = this.pickString(input, ['Code', 'code', 'ID', 'Id', 'uid', 'ZIP', 'AreaCode']) ||
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
    normalizeProxyMate(input) {
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
    normalizeProxyKpi(input) {
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
    normalizeCurrency(input) {
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
    throwIfBusinessError(raw, method) {
        if (this.isBusinessError(raw)) {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BUSINESS_ERROR', 422, `${method} failed: ${raw}`);
        }
    }
    isBusinessError(raw) {
        return raw.trim().startsWith('Error');
    }
    parseJsonArray(raw) {
        const trimmed = raw.trim();
        if (!trimmed || trimmed === 'null') {
            return [];
        }
        try {
            const parsed = JSON.parse(trimmed);
            if (Array.isArray(parsed)) {
                return parsed.filter((it) => !!it && typeof it === 'object');
            }
            if (parsed && typeof parsed === 'object') {
                return [parsed];
            }
            return [];
        }
        catch {
            throw new legacy_soap_error_1.LegacySoapError('LEGACY_BAD_RESPONSE', 502, 'Legacy payload is not valid JSON.');
        }
    }
    pickString(input, keys) {
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
    pickNumber(input, keys) {
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
    collectScalarValues(input) {
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
};
exports.LegacySoapClient = LegacySoapClient;
exports.LegacySoapClient = LegacySoapClient = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [soap_transport_service_1.SoapTransportService,
        config_1.ConfigService])
], LegacySoapClient);
//# sourceMappingURL=legacy-soap.client.js.map