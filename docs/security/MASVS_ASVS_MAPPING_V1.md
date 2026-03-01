# MASVS / ASVS Control Mapping (v1 Baseline)

## MASVS-L2

1. MASVS-NETWORK:
   - HTTPS-only domain whitelist in WebView shell.
   - Mixed content disabled in WebView settings.
2. MASVS-AUTH:
   - JWT access + rotating refresh token pattern in BFF.
3. MASVS-STORAGE:
   - Flutter secure storage for access and refresh tokens.
4. MASVS-PLATFORM:
   - Bridge methods explicitly enumerated, unsupported methods rejected.
5. MASVS-RESILIENCE:
   - Pending: anti-tamper and anti-debug controls in release pipeline.

## ASVS

1. V2 Authentication:
   - Login/refresh/logout API implemented in BFF with legacy SOAP integration.
2. V3 Session Management:
   - Access token TTL + Redis-backed refresh token rotation.
3. V4 Access Control:
   - Bearer guard protects non-public endpoints.
4. V5 Validation:
   - DTO validation via class-validator on all write endpoints.
5. V10 Logging:
   - HTTP logging interceptor with latency and status code.

## Gaps to close before production

1. Add secrets management integration (Vault or cloud secret manager).
2. Add runtime security telemetry export and SIEM forwarding.
3. Add mobile RASP/hardening checks for release builds.
4. Add certificate pinning and release hardening verification for Android and iOS builds.
