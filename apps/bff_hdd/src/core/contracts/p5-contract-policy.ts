import { ProxyKpiRecord, ProxyMateRecord } from '../../adapters/soap/legacy-soap.client';
import { ensureMax, ensureOptionalMax, truncateMax } from './p1-contract-policy';

export const P5_CONTRACT_LIMITS = {
  area: 64,
  year: 4,
  month: 2,
  date: 10,
  code: 64,
  status: 64,
  role: 64,
  name: 128,
  service: 128,
  message: 1024,
  datetime: 40
} as const;

export function enforceProxyMateListContract(
  items: ProxyMateRecord[],
  fieldPrefix = 'proxy.mates.response'
): ProxyMateRecord[] {
  return items.map((item, index) => ({
    code: ensureMax(`${fieldPrefix}[${index}].code`, item.code, P5_CONTRACT_LIMITS.code),
    name: ensureMax(`${fieldPrefix}[${index}].name`, item.name, P5_CONTRACT_LIMITS.name),
    area: ensureOptionalMax(`${fieldPrefix}[${index}].area`, item.area, P5_CONTRACT_LIMITS.area),
    status: ensureOptionalMax(`${fieldPrefix}[${index}].status`, item.status, P5_CONTRACT_LIMITS.status),
    service: ensureOptionalMax(
      `${fieldPrefix}[${index}].service`,
      item.service,
      P5_CONTRACT_LIMITS.service
    ),
    role: ensureOptionalMax(`${fieldPrefix}[${index}].role`, item.role, P5_CONTRACT_LIMITS.role),
    message:
      item.message == null ? null : truncateMax(item.message, P5_CONTRACT_LIMITS.message),
    updatedAt: ensureOptionalMax(
      `${fieldPrefix}[${index}].updatedAt`,
      item.updatedAt,
      P5_CONTRACT_LIMITS.datetime
    )
  }));
}

export function enforceProxyKpiListContract(
  items: ProxyKpiRecord[],
  fieldPrefix = 'proxy.kpi.response'
): ProxyKpiRecord[] {
  return items.map((item, index) => ({
    code: ensureMax(`${fieldPrefix}[${index}].code`, item.code, P5_CONTRACT_LIMITS.code),
    name: ensureMax(`${fieldPrefix}[${index}].name`, item.name, P5_CONTRACT_LIMITS.name),
    status: ensureOptionalMax(`${fieldPrefix}[${index}].status`, item.status, P5_CONTRACT_LIMITS.status),
    service: ensureOptionalMax(
      `${fieldPrefix}[${index}].service`,
      item.service,
      P5_CONTRACT_LIMITS.service
    ),
    role: ensureOptionalMax(`${fieldPrefix}[${index}].role`, item.role, P5_CONTRACT_LIMITS.role),
    message:
      item.message == null ? null : truncateMax(item.message, P5_CONTRACT_LIMITS.message),
    updatedAt: ensureOptionalMax(
      `${fieldPrefix}[${index}].updatedAt`,
      item.updatedAt,
      P5_CONTRACT_LIMITS.datetime
    )
  }));
}
