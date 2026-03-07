"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NoStoreResponse = exports.NO_STORE_RESPONSE_METADATA_KEY = void 0;
const common_1 = require("@nestjs/common");
exports.NO_STORE_RESPONSE_METADATA_KEY = 'security:no-store-response';
const NoStoreResponse = () => (0, common_1.SetMetadata)(exports.NO_STORE_RESPONSE_METADATA_KEY, true);
exports.NoStoreResponse = NoStoreResponse;
//# sourceMappingURL=no-store-response.decorator.js.map