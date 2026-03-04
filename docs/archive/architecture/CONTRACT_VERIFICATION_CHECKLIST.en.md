# Contract Verification Checklist

Doc ID: `HDD-CONTRACT-VERIFY-CHECKLIST`
Version: `v1.4`
Owner: `QA Lead`
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: N/A






1. CN: `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.zh-TW.md`
2. EN: `docs/architecture/CONTRACT_VERIFICATION_CHECKLIST.en.md`

## 1. API contract
1. [ ] OpenAPI path list matches controllers.
2. [ ] `POST` endpoints return expected status code (`200` where specified).
3. [ ] Unauthorized behavior matches contract (`/bootstrap/webview` -> `401` without token).
4. [ ] Error object shape matches OpenAPI schema (`code`, `message`).
5. [ ] Contract field lengths (`maxLength`/`maxItems`) are declared for P0-governed response fields.
6. [ ] P1 boundary validation:
   1. login/refresh/logout request over-length -> `400`.
   2. push/register request over-length -> `400`.
   3. oversized critical response fields -> `502 LEGACY_BAD_RESPONSE`.
   4. `user.name` and bulletin `message` over-length -> truncation.
7. [ ] P2 boundary validation:
   1. oversized shipment response fields -> `502 LEGACY_BAD_RESPONSE`.
   2. over-length delivery/exception request fields -> `400`.
   3. delivery/exception response shape remains `{ ok: boolean }`.
8. [ ] P3 boundary validation:
   1. oversized reservation response fields or shipmentNos > `200` -> `502 LEGACY_BAD_RESPONSE`.
   2. over-length reservation create/delete requests -> `400`.
   3. reservation create response remains `{ reservationNo, mode }` with contract lengths.

Commands:

```bash
npm run bff:route-diff
npm run bff:error-code-map
npm run bff:test -- --runInBand
```

## 2. SOAP mapping contract
1. [ ] `login -> GetLogin` mapping verified.
2. [ ] `shipment -> GetShipment_elf/GetShipment` fallback verified.
3. [ ] `reservation mode=standard|bulk` mapping verified.
4. [ ] `push/register -> UpdateRegID` mapping verified.
5. [ ] `bootstrap/bulletin -> GetBulletin` mapping verified.

Reference:
1. `contracts/legacy/soap-mapping-v1.md`
2. `apps/bff_gateway/src/adapters/soap/legacy-soap.client.ts`

## 3. Bridge contract
1. [ ] 8 methods are accepted by adapter layer.
2. [ ] Unsupported method returns `BRIDGE_UNSUPPORTED_METHOD`.
3. [ ] Invalid payload returns `BRIDGE_INVALID_PAYLOAD`.
4. [ ] Permission denied path returns `BRIDGE_PERMISSION_DENIED`.
5. [ ] Runtime protection returns `BRIDGE_RUNTIME_ERROR`.

Reference:
1. `contracts/bridge/js-bridge-v1.md`
2. `contracts/legacy/bridge-matrix-v1.md`

## 4. WebView cache/session policy
1. [ ] Driver session survives app background/foreground without forced relogin.
2. [ ] Transaction routes use no-cache/no-store strategy.
3. [ ] Header evidence exists for transaction responses (`Cache-Control`, `Pragma`, `Expires`).
4. [ ] Logout clears cookie/storage/cache artifacts.

Reference:
1. `docs/architecture/WAVE4_WEBVIEW_CACHE_POLICY.md`

## 5. Error-code normalization
1. [ ] SOAP timeout/network -> `LEGACY_TIMEOUT` (`502`).
2. [ ] SOAP malformed/protocol -> `LEGACY_BAD_RESPONSE` (`502`).
3. [ ] SOAP business error string -> `LEGACY_BUSINESS_ERROR` (`422`).
4. [ ] Overflow policy follows P0 rules (reject/truncate by field category).

Reference:
1. `contracts/legacy/error-code-mapping-v1.md`

## 6. P0 document governance gate
1. [ ] Core API docs are available in `zh-TW` and `en` pair.
2. [ ] Every legacy method (42/42) has status + reason + owner + milestone.
3. [ ] Cross-language links are present in document header metadata.

## 7. CI final gate
1. [ ] `npm run bff:route-diff`
2. [ ] `npm run bff:error-code-map`
3. [ ] `npm run bff:test -- --runInBand`

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/archive/architecture/CONTRACT_VERIFICATION_CHECKLIST.en.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

