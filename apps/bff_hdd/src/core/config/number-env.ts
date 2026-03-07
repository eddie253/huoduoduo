export function readPositiveInt(
  raw: unknown,
  fallback: number,
  name: string,
  onInvalid?: (message: string) => void
): number {
  const normalizedFallback = Number(fallback);
  if (!Number.isFinite(normalizedFallback) || normalizedFallback <= 0) {
    throw new Error(`Invalid fallback value for ${name}: ${fallback}`);
  }

  const candidate = typeof raw === 'string' ? raw.trim() : raw;
  if (candidate === '' || candidate == null) {
    return Math.floor(normalizedFallback);
  }

  const parsed = Number(candidate);
  if (Number.isFinite(parsed) && parsed > 0) {
    return Math.floor(parsed);
  }

  onInvalid?.(`Invalid ${name} value "${String(raw)}"; fallback to ${Math.floor(normalizedFallback)}.`);
  return Math.floor(normalizedFallback);
}
