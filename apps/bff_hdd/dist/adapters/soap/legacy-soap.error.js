"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LegacySoapError = void 0;
class LegacySoapError extends Error {
    constructor(code, statusCode, message) {
        super(message);
        this.code = code;
        this.statusCode = statusCode;
    }
}
exports.LegacySoapError = LegacySoapError;
//# sourceMappingURL=legacy-soap.error.js.map