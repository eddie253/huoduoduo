import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { SystemVersionResponseDto } from './dto/system-version-response.dto';
export declare class SystemService {
    private readonly legacySoapClient;
    constructor(legacySoapClient: LegacySoapClient);
    getVersion(name: string): Promise<SystemVersionResponseDto>;
}
