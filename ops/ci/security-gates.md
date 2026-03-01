# Security Gates

These checks are mandatory for v1 release branches.

## Build-time gates

1. SAST must pass with no High/Critical findings.
2. SCA must pass with no High/Critical findings without approved waiver.
3. Secret scan must pass with zero hardcoded credentials.
4. SBOM must be generated (CycloneDX) for:
   - `apps/bff_gateway`
   - `apps/mobile_flutter`

## Runtime gates

1. API enforces bearer token validation except explicit public endpoints.
2. WebView allows only approved HTTPS domains.
3. JS bridge rejects unsupported methods with standard error code.
4. Security logging captures request id, route, status code, and latency.

## Release gates

1. Ring rollout metrics remain within SLO:
   - Crash free sessions >= 99.5%
   - Login success rate within 2% of baseline
   - No elevated 5xx trend
2. Rollback playbook validated during pre-production drill.

