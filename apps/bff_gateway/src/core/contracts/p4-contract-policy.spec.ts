import {
  P4_CONTRACT_LIMITS,
  enforceHealthResponseContract,
  normalizeErrorResponseContract
} from './p4-contract-policy';

describe('p4-contract-policy', () => {
  it('enforceHealthResponseContract returns payload when fields are valid', () => {
    const payload = {
      status: 'ok',
      service: 'bff_gateway',
      timestamp: '2026-03-04T01:20:00.000Z'
    };

    const result = enforceHealthResponseContract(payload);
    expect(result).toEqual(payload);
  });

  it('normalizeErrorResponseContract truncates over-length message to 1024', () => {
    const result = normalizeErrorResponseContract('LEGACY_BAD_RESPONSE', 'x'.repeat(2000));
    expect(result.code).toBe('LEGACY_BAD_RESPONSE');
    expect(result.message.length).toBe(P4_CONTRACT_LIMITS.errorMessage);
  });

  it('normalizeErrorResponseContract falls back to internal code when code exceeds 64', () => {
    const result = normalizeErrorResponseContract(`C${'x'.repeat(64)}`, 'failed');
    expect(result.code).toBe('INTERNAL_SERVER_ERROR');
  });
});
