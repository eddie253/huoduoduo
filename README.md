# huoduoduo Monorepo

This repository is the active migration workspace for:

1. `apps/mobile_flutter` (Flutter client)
2. `apps/bff_gateway` (NestJS BFF in front of legacy SOAP)
3. `contracts` (OpenAPI + bridge + legacy mapping contracts)
4. `ops` (CI and deployment scripts)
5. `docs` (architecture/security/UAT evidence)

## Legacy freeze policy

Legacy Android source is frozen and kept local-only in this working copy.

Reference:

1. `docs/architecture/LEGACY_BASELINE_FREEZE.md`
2. `contracts/legacy/soap-mapping-v1.md`
3. `contracts/legacy/bridge-matrix-v1.md`
4. `contracts/legacy/error-code-mapping-v1.md`

## Local verification

```bash
npm run bff:verify
cd apps/mobile_flutter
flutter analyze
flutter test
```
