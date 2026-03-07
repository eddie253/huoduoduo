import { Injectable } from '@nestjs/common';
import { LegacySoapClient } from '../../adapters/soap/legacy-soap.client';
import { ensureMax } from '../../core/contracts/p1-contract-policy';
import {
  P9_CONTRACT_LIMITS,
  enforceSystemVersionResponseContract,
  parseLegacyVersionCode
} from '../../core/contracts/p9-contract-policy';
import { SystemVersionResponseDto } from './dto/system-version-response.dto';

@Injectable()
export class SystemService {
  constructor(private readonly legacySoapClient: LegacySoapClient) {}

  async getVersion(name: string): Promise<SystemVersionResponseDto> {
    const normalizedName = ensureMax('system.version.request.name', name, P9_CONTRACT_LIMITS.versionName);
    const raw = await this.legacySoapClient.getVersion(normalizedName);
    const versionCode = parseLegacyVersionCode(raw);
    return enforceSystemVersionResponseContract({
      name: normalizedName,
      versionCode
    });
  }
}
