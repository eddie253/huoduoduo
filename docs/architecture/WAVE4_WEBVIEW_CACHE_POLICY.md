# Wave 4 WebView Cache Policy

Doc ID: HDD-DOCS-ARCHITECTURE-WAVE4-WEBVIEW-CACHE-POLICY
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Goal

Keep long-lived login session stable while ensuring transaction data is always fresh.

## Decision

Use a hybrid policy:

1. Session state is preserved (cookie + webview instance keep-alive).
2. Transaction pages and transaction APIs are no-store/no-cache.
3. Logout performs full local web session cleanup.

This avoids the two extreme modes:

1. Global no-cache (safe but poor UX/performance).
2. Global cache-default (fast but stale-risk for real-time operations).

## Scope

1. Flutter host (`flutter_inappwebview`).
2. BFF response headers for REST and bootstrap contract.
3. Legacy web transaction pages used in WebView shell.

## Policy Matrix

| Layer | Session pages | Transaction pages |
|---|---|---|
| WebView document load | `LOAD_DEFAULT` | `RELOAD_IGNORING_LOCAL_CACHE_DATA` |
| HTTP response headers | `private, max-age=<short>` allowed | `no-store, no-cache, must-revalidate` |
| Client storage | keep cookies and web state | no persistent snapshot for transaction payload |
| Re-entry behavior | restore prior session context | force fresh fetch |

## Flutter Rules (`flutter_inappwebview`)

1. Use `InAppWebViewKeepAlive` for long-running driver session route.
2. Keep `clearCache: false` during normal app lifecycle.
3. On navigation, classify URL:
1. If transaction route -> call `loadUrl` with `URLRequest(cachePolicy: RELOAD_IGNORING_LOCAL_CACHE_DATA)`.
2. Else -> use default cache policy.
4. Keep strict whitelist host validation (already enabled).
5. Keep `mixedContentMode` deny policy (already enabled).
6. On logout:
1. clear cookies
2. clear web storage
3. clear webview cache

## BFF and Legacy Header Requirements

For transaction endpoints/pages, enforce:

1. `Cache-Control: no-store, no-cache, must-revalidate`
2. `Pragma: no-cache`
3. `Expires: 0`

For non-transaction shell/bootstrap documents, allow conservative private caching only when business accepts staleness window.

## Transaction Route Classification (v1)

Treat these as transaction-critical:

1. shipment query/result pages
2. delivery submit
3. exception submit
4. reservation create/delete

If route classification is unknown, default to transaction-safe (`no-cache`).

## Security and Compliance Mapping

1. MASVS-L2: reduce WebView data exposure and stale-state abuse surface.
2. ASVS V3/V4: session handling and data freshness controls are explicit and testable.
3. SSDF: policy is documented, testable, and CI-checkable.

## Verification Checklist

1. Login -> background -> foreground keeps session (no forced relogin).
2. Transaction submit after web update reads latest data (no stale replay page).
3. Browser devtools/proxy confirms no-store headers on transaction routes.
4. Logout clears web session artifacts and next entry requires auth again.
5. Android and iOS behavior matches for the same URL set.

## Rollout

1. Implement in Android first.
2. Mirror in iOS host when Mac pipeline is active.
3. Record evidence in next wave evidence doc with request/response header snapshot.

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/architecture/WAVE4_WEBVIEW_CACHE_POLICY.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

